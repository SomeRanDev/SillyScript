package sillyscript.compiler.parser.subparsers;

import sillyscript.compiler.parser.subparsers.ExpressionParser.ExpressionParserContext;
import sillyscript.compiler.parser.UntypedAst.UntypedDefDeclaration;
import sillyscript.MacroUtils.returnIfError;
import sillyscript.Positioned;
import sillyscript.compiler.parser.ParserResult.ParseResult;
using sillyscript.extensions.ArrayExt;

/**
	Handles the parsing of `def` declarations.
**/
@:access(sillyscript.compiler.parser.Parser)
class DefDeclParser {
	public static function parseDef(context: ExpressionParserContext): ParseResult<Positioned<UntypedDefDeclaration>> {
		final parser = context.parser;
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
			switch(parseArgument(context)) {
				case Success(result): arguments.push(result);
				case NoMatch: {}
				case Error(parseErrors): {
					errors.pushArray(parseErrors);
				}
			}

			parser.ignoreWhitespace();

			switch(parser.peek()) {
				case Comma: parser.expectOrFatal(Comma);
				case ParenthesisClose: {}
				case _: return Error(errors.concat([{
					value: ExpectedMultiple([Comma, ParenthesisClose]),
					position: parser.here()
				}]));
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
			case Error(e): return Error(e);
		}

		returnIfError(parser.expect(Colon));
		returnIfError(parser.expect(IncrementIndent));

		final content = switch(ExpressionParser.parseListOrDictionaryPostColonIdent(context)) {
			case Success(result): result;
			case NoMatch: return Error([{ value: ExpectedListOrDictionaryEntries, position: parser.here() }]);
			case Error(e): return Error(e);
		}

		returnIfError(parser.expect(DecrementIndent));

		return Success({
			value: {
				name: name,
				arguments: arguments,
				returnType: returnType,
				content: content
			},
			position: parser.makePositionFrom(start, false)
		});
	}

	static function parseArgument(context: ExpressionParserContext): ParseResult<Positioned<{
		name: Positioned<String>,
		type: Positioned<AmbiguousType>,
		defaultValue: Null<Positioned<UntypedAst>>
	}>> {
		final parser = context.parser;
		final tokenWithPosition = parser.peekWithPosition();
		if(tokenWithPosition == null) return NoMatch;

		final name = switch(tokenWithPosition.value) {
			case Identifier(identifier) if(parser.peek(1) == Colon): {
				parser.expectOrFatal(Identifier(identifier));
				parser.expectOrFatal(Colon);
				identifier;
			}
			case _: return NoMatch;
		}

		final type = switch(TypeParser.parseType(parser)) {
			case Success(result): {
				result;
			}
			case NoMatch: {
				return Error([{
					value: ExpectedType,
					position: parser.here()
				}]);
			}
			case Error(errors): {
				return Error(errors);
			}
		}

		final expression = switch(parser.peek()) {
			case Equals: {
				parser.expectOrFatal(Equals);

				switch(ExpressionParser.parseExpression(context, false)) {
					case Success(expression): expression;
					case NoMatch: return Error([{ value: ExpectedExpression, position: parser.here() }]);
					case Error(error): return Error(error);
				}
			}
			case _: {
				null;
			}
		}

		final nameWithPosition: Positioned<String> = {
			value: name,
			position: tokenWithPosition.position
		};

		return Success({
			value: { name: nameWithPosition, type: type, defaultValue: expression },
			position: tokenWithPosition.position.merge(expression != null ? expression.position : type.position),
		});
	}
}