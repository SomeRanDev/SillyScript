package sillyscript.compiler.parser.subparsers;

import sillyscript.compiler.parser.subparsers.ExpressionParser.ExpressionParserContext;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration;
import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.compiler.parser.UntypedAst.UntypedDeclaration;
import sillyscript.compiler.typer.SillyType;
import sillyscript.MacroUtils.returnIfError;
import sillyscript.Positioned;

/**
	Handles the parsing of `def` declarations.
**/
@:access(sillyscript.compiler.parser.Parser)
class CustomSyntaxDeclParser {
	public static function parseCustomSyntaxDeclaration(context: ExpressionParserContext): ParseResult<
		Positioned<UntypedCustomSyntaxDeclaration>
	> {
		final parser = context.parser;
		final start = parser.currentIndex;

		switch(parser.peek()) {
			case Keyword(Syntax) if(parser.peek(1).match(Identifier(_)) && parser.peek(2) == Colon): {
				parser.expectOrFatal(Keyword(Syntax));
			}
			case _: return NoMatch;
		}

		final name: Positioned<String> = {
			final tokenWithPosition = parser.peekWithPosition();
			switch(tokenWithPosition?.value) {
				case Identifier(content) if(tokenWithPosition != null): {
					parser.advance();
					{ value: content, position: tokenWithPosition.position }
				}
				case _: return Error([{
					value: Expected(Identifier("")),
					position: parser.here()
				}]);
			}
		}

		returnIfError(parser.expect(Colon));
		returnIfError(parser.expect(IncrementIndent));

		final declarations: Array<Positioned<UntypedDeclaration>> = [];
		final errors: Array<Positioned<ParserError>> = [];
		final patterns: Array<UntypedCustomSyntaxDeclarationPattern> = [];

		while(true) {
			// Check if we should stop parsing
			final c = parser.peekWithPosition();
			if(c == null || c.value == DecrementIndent || c.value == EndOfFile) {
				break;
			}

			// Check for declarations
			switch(c.value) {
				case Keyword(Def): {
					switch(DefDeclParser.parseDef(context)) {
						case Success(result): {
							declarations.push(result.map(d -> UntypedDeclaration.Def(d)));
							continue;
						}
						case NoMatch: {}
						case Error(defParserErrors): {
							for(e in defParserErrors) {
								errors.push(e);
							}
							continue;
						}
					}
				}
				case Keyword(Pattern): {
					parser.expectOrFatal(Keyword(Pattern));

					var returnType: Null<Positioned<AmbiguousType>> = null;

					switch(parser.peek()) {
						case Arrow: {
							returnIfError(parser.expect(Arrow));

							switch(TypeParser.parseType(parser)) {
								case Success(result): {
									returnType = result;
								}
								case NoMatch: {
									errors.push({
										value: ExpectedType,
										position: parser.here()
									});
								}
								case Error(typeParseErrors): {
									for(e in typeParseErrors) {
										errors.push(e);
									}
								}
							}
						}
						case _:
					}

					returnIfError(parser.expect(Colon));
					returnIfError(parser.expect(IncrementIndent));

					final tokens: Array<CustomSyntaxDeclarationToken> = [];
					var identIncrementCount = 0;
					while(true) {
						switch(parser.peek()) {
							case TriangleOpen: {
								final state = parser.getState();
								switch(parseSyntaxTemplateArgument(parser)) {
									case Success(argument): {
										tokens.push(
											ExpressionInput(argument.value.name, argument.value.type)
										);
									}

									// If error or no match, just revert back to old state and
									// consume triangle token.
									case _: {
										parser.revertToState(state);
										parser.expectOrFatal(TriangleOpen);
										tokens.push(Token(TriangleOpen));
									}
								}
							}
							case IncrementIndent: {
								parser.expectOrFatal(IncrementIndent);
								tokens.push(Token(IncrementIndent));
								identIncrementCount++;
							}
							case DecrementIndent if(identIncrementCount == 0): {
								break;
							}
							case DecrementIndent: {
								parser.expectOrFatal(DecrementIndent);
								tokens.push(Token(DecrementIndent));
								identIncrementCount--;
							}
							case EndOfFile: {
								break;
							}
							case null: {
								return Error([{
									value: UnexpectedEndOfTokens,
									position: parser.here(),
								}]);
							}
							case token: {
								parser.advance();
								tokens.push(Token(token));
							}
						}
					}

					returnIfError(parser.expect(DecrementIndent));

					final returnType: Positioned<AmbiguousType> = returnType ?? {
						value: Known({
							kind: Dictionary(SillyType.ANY),
							nullable: false,
							role: ""
						}),
						position: c.position
					};
					patterns.push({
						returnType: returnType,
						tokenPattern: tokens
					});
				}
				case _: {
					return Error([{
						value: ExpectedMultiple([Keyword(Def), Keyword(Pattern)]),
						position: parser.here()
					}]);
				}
			}
		}

		final maybeError = parser.expect(DecrementIndent);
		if(maybeError != null) {
			errors.push(maybeError);
		}

		if(errors.length > 0) {
			return Error(errors);
		}

		return Success({
			value: new UntypedCustomSyntaxDeclaration(name, declarations, patterns),
			position: parser.makePositionFrom(start, false)
		});
	}

	static function parseSyntaxTemplateArgument(parser: Parser): ParseResult<Positioned<{
		name: Positioned<String>,
		type: Positioned<AmbiguousType>,
	}>> {
		switch(parser.peek()) {
			case TriangleOpen: {}
			case _: return NoMatch;
		}

		final tokenWithPosition = parser.peekWithPosition(1);
		if(tokenWithPosition == null) return NoMatch;

		return switch(tokenWithPosition.value) {
			case Identifier(identifier) if(parser.peek(2) == Colon): {
				parser.expectOrFatal(TriangleOpen);
				parser.expectOrFatal(Identifier(identifier));
				parser.expectOrFatal(Colon);
				
				switch(TypeParser.parseType(parser)) {
					case Success(result): {
						returnIfError(parser.expect(TriangleClose));

						final identifierWithPosition: Positioned<String> = {
							value: identifier,
							position: tokenWithPosition.position
						};
						Success({
							value: { name: identifierWithPosition, type: result },
							position: tokenWithPosition.position.merge(result.position)
						});
					}
					case NoMatch: {
						Error([{
							value: ExpectedType,
							position: parser.here()
						}]);
					}
					case Error(errors): {
						Error(errors);
					}
				}
			}
			case _: NoMatch;
		}
	}
}