package sillyscript.compiler.parser.subparsers;

import sillyscript.compiler.Result.PositionedResult;
import haxe.ds.Either;
import sillyscript.compiler.parser.subparsers.ExpressionParser.ExpressionParserContext;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration;
import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.compiler.parser.UntypedAst.UntypedDeclaration;
import sillyscript.compiler.typer.SillyType;
import sillyscript.MacroUtils.returnIfError;
import sillyscript.MacroUtils.returnIfErrorWith;
import sillyscript.Positioned;
using sillyscript.extensions.ArrayExt;

/**
	Handles the parsing of `def` declarations.
**/
@:access(sillyscript.compiler.parser.Parser)
class CustomSyntaxDeclParser {
	public static function parseCustomSyntaxDeclaration(
		context: ExpressionParserContext
	): ParseResult<Positioned<UntypedCustomSyntaxDeclaration>> {
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

		final deferredResult = UntypedCustomSyntaxDeclaration.deferred();
		final positionedDeferredResult: Positioned<UntypedCustomSyntaxDeclaration> = {
			value: deferredResult,
			position: Position.deferred(name.position)
		};

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
							errors.pushArray(defParserErrors);
							continue;
						}
					}
				}
				case Keyword(Syntax): {
					switch(CustomSyntaxDeclParser.parseCustomSyntaxDeclaration(context)) {
						case Success(result): {
							declarations.push(result.map(s -> UntypedDeclaration.CustomSyntax(s)));
							continue;
						}
						case NoMatch: {}
						case Error(syntaxParserErrors): {
							errors.pushArray(syntaxParserErrors);
							continue;
						}
					}
				}
				case Keyword(Pattern): {
					parser.expectOrFatal(Keyword(Pattern));

					var returnType: Null<Positioned<AmbiguousType>> = null;

					switch(parser.peek()) {
						case Arrow: {
							parser.expectOrFatal(Arrow);

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
									errors.pushArray(typeParseErrors);
								}
							}
						}
						case _:
					}

					returnIfErrorWith(parser.expect(Colon), errors);
					returnIfErrorWith(parser.expect(IncrementIndent), errors);

					final tokens: Array<CustomSyntaxDeclarationToken> = [];
					var identIncrementCount = 0;
					while(true) {
						switch(parser.peek()) {
							case TriangleOpen: {
								switch(parseSyntaxTemplateArgumentWithTriangleBrackets(
									context,
									name.value,
									positionedDeferredResult
								)) {
									case Success(tokenResult): tokens.push(tokenResult);
									case Error(e): {
										return Error(errors.concat(e));
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
								return Error(errors.concat([{
									value: UnexpectedEndOfTokens,
									position: parser.here(),
								}]));
							}
							case token: {
								parser.advance();
								tokens.push(Token(token));
							}
						}
					}

					returnIfErrorWith(parser.expect(DecrementIndent), errors);

					final returnType: Positioned<AmbiguousType> = returnType ?? {
						value: Known({
							kind: Dictionary(SillyType.ANY),
							nullable: false,
							role: null
						}),
						position: c.position
					};
					patterns.push({
						returnType: returnType,
						tokenPattern: tokens
					});
				}
				case _: {
					return Error(errors.concat([{
						value: ExpectedMultiple([Keyword(Def), Keyword(Pattern)]),
						position: parser.here()
					}]));
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

		positionedDeferredResult.value.setAll(name, declarations, patterns);
		positionedDeferredResult.position.undefer(parser.makePositionFrom(start, false));

		return Success(positionedDeferredResult);
	}

	static function parseSyntaxTemplateArgumentWithTriangleBrackets(
		context: ExpressionParserContext,
		currentSyntaxName: String,
		deferredSelf: Positioned<UntypedCustomSyntaxDeclaration>
	): PositionedResult<CustomSyntaxDeclarationToken, ParserError> {
		final parser = context.parser;
		final state = parser.getState();
		return switch(parseSyntaxTemplateArgument(context, currentSyntaxName, deferredSelf)) {
			case Success(argument): {
				switch(argument.value.type.value) {
					case Left(ambiguousType): {
						Success(ExpressionInput(
							argument.value.name,
							argument.value.type.map(_ -> ambiguousType)
						));
					}
					case Right(customSyntaxId): {
						Success(CustomSyntaxInput(argument.value.name, customSyntaxId));
					}
				}
			}

			// `UnknownSyntaxName` should be returned since it is very obviously intended to be a 
			// valid pattern.
			case Error([{ value: UnknownSyntaxName(name), position: position }]): {
				Error([{ value: UnknownSyntaxName(name), position: position }]);
			}

			// If error or no match, just revert back to old state and consume triangle token.
			case _: {
				parser.revertToState(state);
				parser.expectOrFatal(TriangleOpen);
				Success(Token(TriangleOpen));
			}
		}
	}

	static function parseSyntaxTemplateArgument(
		context: ExpressionParserContext,
		currentSyntaxName: String,
		deferredSelf: Positioned<UntypedCustomSyntaxDeclaration>
	): ParseResult<Positioned<{
		name: Positioned<String>,
		type: Positioned<Either<AmbiguousType, CustomSyntaxId>>,
	}>> {
		final parser = context.parser;
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
				
				final identifierWithPosition: Positioned<String> = {
					value: identifier,
					position: tokenWithPosition.position
				};

				final maybeSyntaxToken = parser.peekWithPosition();
				switch(maybeSyntaxToken?.value) {
					case Keyword(Syntax): {
						parser.expectOrFatal(Keyword(Syntax));
						returnIfError(parser.expect(ExclamationPoint));

						final maybeSyntaxIdentifier = parser.peekWithPosition();
						final syntaxName = switch(maybeSyntaxIdentifier) {
							case { value: Identifier(name) }: {
								parser.expectOrFatal(Identifier(name));
								name;
							}
							case _: return Error([{
								value: Expected(Identifier("")),
								position: parser.here()
							}]);
						}

						returnIfError(parser.expect(TriangleClose));

						final syntaxDecl = if(syntaxName == currentSyntaxName) {
							deferredSelf;
						} else {
							context.syntaxScope?.findSyntaxDeclaration(syntaxName);
						}
						return if(syntaxDecl != null) {
							Success({
								value: {
									name: identifierWithPosition,
									type: syntaxDecl.map(t -> Right(t.id))
								},
								position: tokenWithPosition.position.merge(maybeSyntaxIdentifier.position)
							});
						} else {
							Error([{
								value: UnknownSyntaxName(syntaxName),
								position: maybeSyntaxIdentifier.position
							}]);
						}
					}
					case _:
				}

				switch(TypeParser.parseType(parser)) {
					case Success(result): {
						returnIfError(parser.expect(TriangleClose));

						Success({
							value: {
								name: identifierWithPosition,
								type: result.map(t -> Left(t))
							},
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