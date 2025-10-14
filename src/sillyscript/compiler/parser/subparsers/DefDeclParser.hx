package sillyscript.compiler.parser.subparsers;

import sillyscript.compiler.parser.UntypedAst.UntypedDefDeclaration;
import sillyscript.compiler.typer.SillyType;
import sillyscript.MacroUtils.returnIfError;
import sillyscript.Positioned;
import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.compiler.typer.Typer;

/**
	Handles the parsing of `def` declarations.
**/
@:access(sillyscript.compiler.parser.Parser)
class DefDeclParser {
	public static function parseDef(parser: Parser): ParseResult<Positioned<UntypedDefDeclaration>> {
		final start = parser.currentIndex;

		switch(parser.peek()) {
			case Keyword(Def) if(parser.peek(1).match(Identifier(_))): {
				parser.expectOrFatal(Keyword(Def));
			}
			case _: return NoMatch;
		}

		final name = {
			final tokenWithPosition = parser.peekWithPosition();
			switch(tokenWithPosition?.value) {
				case Identifier(content): {
					parser.advance();
					content;
				}
				case _: return Error([{
					value: Expected(Identifier("")),
					position: parser.here()
				}]);
			}
		}

		returnIfError(parser.expect(ParenthesisOpen));

		parser.ignoreWhitespace();

		final arguments = [];
		final errors = [];
		while(parser.peek() != ParenthesisClose) {
			switch(parseArgument(parser)) {
				case Success(result): arguments.push(result);
				case NoMatch: {}
				case Error(parseErrors): {
					for(e in parseErrors) {
						errors.push(e);
					}
				}
			}

			parser.ignoreWhitespace();

			switch(parser.peek()) {
				case Comma: parser.expectOrFatal(Comma);
				case ParenthesisClose: {}
				case _: return Error([{
					value: ExpectedMultiple([Comma, ParenthesisClose]),
					position: parser.here()
				}]);
			}

			parser.ignoreWhitespace();
		}

		if(errors.length != 0) {
			return Error(errors);
		}

		returnIfError(parser.expect(ParenthesisClose));
		returnIfError(parser.expect(Arrow));
		
		final returnType = switch(TypeParser.parseType(parser)) {
			case Success(result): result;
			case NoMatch: return Error([{ value: ExpectedType, position: parser.here() }]);
			case Error(errors): return Error(errors);
		}

		returnIfError(parser.expect(Colon));
		returnIfError(parser.expect(IncrementIndent));

		final content = switch(ExpressionParser.parseListOrDictionaryPostColonIdent(parser)) {
			case Success(result): result;
			case NoMatch: return Error([{ value: ExpectedListOrDictionaryEntries, position: parser.here() }]);
			case Error(errors): return Error(errors);
		}

		returnIfError(parser.expect(DecrementIndent));

		return Success({
			value: {
				name: name,
				arguments: arguments,
				returnType: returnType,
				content: content
			},
			position: parser.makePositionFrom(start)
		});
	}

	static function parseArgument(parser: Parser): ParseResult<Positioned<{
		name: Positioned<String>,
		type: Positioned<SillyType>
	}>> {
		final tokenWithPosition = parser.peekWithPosition();
		if(tokenWithPosition == null) return NoMatch;

		return switch(tokenWithPosition.value) {
			case Identifier(identifier) if(parser.peek(1) == Colon): {
				parser.expectOrFatal(Identifier(identifier));
				parser.expectOrFatal(Colon);
				
				switch(TypeParser.parseType(parser)) {
					case Success(result): {
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