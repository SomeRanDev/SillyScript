package sillyscript.compiler.parser.subparsers;

import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.compiler.parser.UntypedAst.UntypedEnumDeclaration;
import sillyscript.MacroUtils.returnIfError;
import sillyscript.Positioned;

/**
	Handles the parsing of `enum` declarations.
**/
@:access(sillyscript.compiler.parser.Parser)
class EnumDeclParser {
	public static function parseEnum(parser: Parser): ParseResult<Positioned<UntypedEnumDeclaration>> {
		final start = parser.getState();

		switch(parser.peek()) {
			case Keyword(Enum) if(parser.peek(1).match(Identifier(_))): {
				parser.expectOrFatal(Keyword(Enum));
			}
			case _: return NoMatch;
		}

		final name: Positioned<String> = {
			final tokenWithPosition = parser.peekWithPosition();
			switch(tokenWithPosition?.value) {
				case Identifier(content) if(tokenWithPosition != null): {
					parser.advance();
					{ value: content, position: tokenWithPosition.position };
				}
				case _: return Error([{
					value: Expected(Identifier("")),
					position: parser.here()
				}]);
			}
		}

		final type = switch(parser.peek()) {
			case Arrow: {
				returnIfError(parser.expect(Arrow));

				switch(TypeParser.parseType(parser)) {
					case Success(result): result;
					case NoMatch: return Error([{ value: ExpectedType, position: parser.here() }]);
					case Error(errors): return Error(errors);
				}
			}
			case _: {
				null;
			}
		}

		returnIfError(parser.expect(Colon));
		returnIfError(parser.expect(IncrementIndent));

		final cases: Array<Positioned<String>> = [];
		while(true) {
			final c = parser.peekWithPosition();
			if(c == null) break;

			switch(c.value) {
				case Identifier(content): {
					returnIfError(parser.expect(Identifier(content)));
					returnIfError(parser.expect(Semicolon));
					cases.push({
						value: content,
						position: c.position
					});
				}
				case DecrementIndent: {
					returnIfError(parser.expect(DecrementIndent));
					break;
				}
				case _: {
					return Error([{
						value: Expected(Identifier("")),
						position: c.position
					}]);
				}
			}
		}

		return Success({
			value: {
				name: name,
				type: type,
				cases: cases
			},
			position: parser.makePositionFromState(start, false)
		});
	}
}