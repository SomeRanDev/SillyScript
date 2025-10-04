package sillyscript.compiler.parser.subparsers;

import sillyscript.compiler.parser.UntypedAst.UntypedDeclaration;
import sillyscript.compiler.parser.UntypedAst.UntypedDictionaryEntry;
import haxe.ds.Either;
import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.MacroUtils.returnIfError;
import sillyscript.Position.Positioned;

/**
	Used internally by `parseListOrDictionaryPostColonIdent` to track whether a list or dictionary 
	is being parsed.
**/
enum ParseKind {
	Unknown;
	List;
	Dictionary;
}

/**
	Handles the parsing of basic values, lists, and dictionaries in SillyScript.
**/
@:access(sillyscript.compiler.parser.Parser)
class ValueParser {
	/**
		Parses the contents of a list or dictionary as one would expect following a colon and
		incremented indent.
	**/
	public static function parseListOrDictionaryPostColonIdent(
		parser: Parser
	): ParseResult<Positioned<UntypedAst>> {
		var kind = Unknown;

		final start = parser.currentIndex;
		final listEntries: Array<Positioned<UntypedAst>> = [];
		final dictionaryEntries: Array<Positioned<UntypedDictionaryEntry>> = [];
		final declarations: Array<Positioned<UntypedDeclaration>> = [];
		final errors: Array<Positioned<ParserError>> = [];

		while(true) {
			// Check if we should stop parsing
			final c = parser.peek();
			if(c == DecrementIndent || c == EndOfFile) {
				break;
			}

			// Check for declarations
			switch(parser.peek()) {
				case Keyword(Def): {
					switch(DefParser.parseDef(parser)) {
						case Success(result): {
							declarations.push(result.map(d -> Def(d)));
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
				case _:
			}

			// Parse list or dictionary entry if all else fails...
			switch(parseListOrDictionaryEntry(parser)) {
				case Success(Left(dictionaryEntry)): {
					if(kind == Unknown) kind = Dictionary;
					switch(kind) {
						case List: errors.push({
							value: UnexpectedDictionaryEntryWhileParsingList,
							position: dictionaryEntry.position
						});
						case Unknown | Dictionary: dictionaryEntries.push(dictionaryEntry);
					}
				}
				case Success(Right(listEntry)): {
					if(kind == Unknown) kind = List;
					switch(kind) {
						case Dictionary: errors.push({
							value: UnexpectedListEntryWhileParsingDictionary,
							position: listEntry.position
						});
						case Unknown | List: listEntries.push(listEntry);
					}
				}
				case NoMatch: {
					errors.push({ value: NoMatch, position: parser.here() });
					break;
				}
				case Error(entryParseErrors): {
					for(e in entryParseErrors) {
						errors.push(e);
					}
					break;
				}
			}

			if(parser.peek(-1) != DecrementIndent) {
				returnIfError(parser.expect(Semicolon));
			}
		}

		if(errors.length > 0) {
			return Error(errors);
		}

		return Success({
			value: switch(kind) {
				case Unknown: List([], []);
				case List: List(listEntries, declarations);
				case Dictionary: Dictionary(dictionaryEntries, declarations);
			},
			position: parser.makePositionFrom(start)
		});
	}

	/**
		First attempts to parse: `<identifier>: <ast entry>`.
		If successful, it returns `Left`.

		If it cannot, it then attempts to parse: `<ast entry>` and returns `Right`.
	**/
	static function parseListOrDictionaryEntry(parser: Parser): ParseResult<Either<
		Positioned<UntypedDictionaryEntry>,
		Positioned<UntypedAst>
	>> {
		switch(parseDictionaryEntry(parser)) {
			case Success(result): return Success(Left(result));
			case Error(error): return Error(error);
			case _:
		}

		return parseExpression(parser, false).map(null, (result) -> Either.Right(result));
	}

	/**
		Parses the following pattern: `<identifier>: <ast entry>`.
	**/
	static function parseDictionaryEntry(parser: Parser): ParseResult<Positioned<{
		key: Positioned<String>,
		value: Positioned<UntypedAst>
	}>> {
		final identifierToken = parser.peekWithPosition();
		if(identifierToken == null) return NoMatch;

		return switch(identifierToken.value) {
			case Identifier(content) if(parser.peek(1) == Colon): {
				parser.expectOrFatal(Identifier(content));
				parser.expectOrFatal(Colon);

				switch(parseExpression(parser, true)) {
					case Success(result): {
						final key: Positioned<String> = {
							value: content,
							position: identifierToken.position
						};
						final dictionaryEntry = { key: key, value: result };
						Success({
							value: dictionaryEntry,
							position: identifierToken.position.merge(result.position)
						});
					}
					case NoMatch: Error([{ value: ExpectedExpression, position: parser.here() }]);
					case Error(error): Error(error);
				}
			}
			case _: NoMatch;
		}
	}

	/**
		Parse an entry to `UntypedAst`.

		If `colonExists` is `true`, a colon was parsed prior to this call.
	**/
	static function parseExpression(
		parser: Parser,
		colonExists: Bool
	): ParseResult<Positioned<UntypedAst>> {
		final firstToken = parser.peekWithPosition();
		if(firstToken == null) return Error([{
			value: ExpectedExpression,
			position: parser.here()
		}]);

		final simpleEntry: Null<Value> = switch(firstToken.value) {
			case Null: Null;
			case Bool(value): Bool(value);
			case Int(content): Int(content);
			case Float(content): Float(content);
			case String(content): String(content);
			case _: null;
		}

		final expression: ParseResult<Positioned<UntypedAst>> = switch(firstToken.value) {
			case _ if(simpleEntry != null): {
				parser.advance();
				Success({
					value: Value(simpleEntry),
					position: firstToken.position
				});
			}
			case IncrementIndent if(colonExists): {
				parser.expectOrFatal(IncrementIndent);
				parseListOrDictionaryPostColonIdent(parser).map(
					{ value: ExpectedListOrDictionaryEntries, position: parser.here() },
					function(result) {
						parser.advanceIfMatch(DecrementIndent);
						return result;
					}
				);
			}
			case Colon if(!colonExists && parser.peek(1) == IncrementIndent): {
				parser.expectOrFatal(Colon);
				parser.expectOrFatal(IncrementIndent);
				parseListOrDictionaryPostColonIdent(parser).map(
					{ value: ExpectedListOrDictionaryEntries, position: parser.here() },
					function(result) {
						parser.advanceIfMatch(DecrementIndent);
						return result;
					}
				);
			}
			// case Identifier(identifier) if(parser.peek(1) == ParenthesisOpen): {
			// 	parser.expectOrFatal(Identifier(identifier));
			// 	parser.expectOrFatal(ParenthesisOpen);
			// 	parseCallArgumentsPostParenthesisOpen(parser, identifier);
			// }
			case Identifier(identifier): {
				parser.advance();
				Success({
					value: Identifier(identifier),
					position: firstToken.position
				});
			}
			case _: {
				NoMatch;
			}
		}

		return switch(expression) {
			case Success(innerExpression): {
				switch(parsePostExpression(parser, innerExpression)) {
					case Success(result): Success(result);
					case NoMatch: expression;
					case Error(errors): Error(errors);
				}
			}
			case notSuccess: {
				notSuccess;
			}
		}
	}

	static function parsePostExpression(
		parser: Parser,
		expression: Positioned<UntypedAst>
	): ParseResult<Positioned<UntypedAst>> {
		final firstToken = parser.peekWithPosition();
		if(firstToken == null) return NoMatch;

		return switch(firstToken.value) {
			case ParenthesisOpen: {
				parser.expectOrFatal(ParenthesisOpen);
				parseCallArgumentsPostParenthesisOpen(parser, expression);
			}
			case _: {
				NoMatch;
			}
		}
	}

	/**
		Parses the contents of call arguments after the opening parenthesis is parsed.
	**/
	static function parseCallArgumentsPostParenthesisOpen(
		parser: Parser,
		calledAst: Positioned<UntypedAst>
	): ParseResult<Positioned<UntypedAst>> {
		function parseArgument() {
			final name = switch(parser.peek()) {
				case Identifier(identifier) if(parser.peek(1) == Colon): {
					parser.expectOrFatal(Identifier(identifier));
					parser.expectOrFatal(Colon);
					identifier;
				}
				case _: null;
			}

			return parseExpression(parser, name != null).map(
				{ value: ExpectedExpression, position: parser.here() },
				(ast) -> { name: name, value: ast }
			);
		}

		final start = parser.currentIndex - 1; // Including previous token (open parenthesis).

		parser.ignoreWhitespace();

		final arguments = [];
		while(parser.peek() != ParenthesisClose) {
			switch(parseArgument()) {
				case Success(result): arguments.push(result);
				case NoMatch: {}
				case Error(error): return Error(error);
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

		parser.expectOrFatal(ParenthesisClose);
		
		return Success({
			value: Call(calledAst, arguments),
			position: parser.makePositionFrom(start)
		});
	}
}
