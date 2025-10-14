package sillyscript.compiler.parser.subparsers;

import haxe.CallStack;
import sillyscript.compiler.parser.subparsers.DefDeclParser;
import haxe.ds.Either;
import sillyscript.compiler.parser.custom_syntax.CustomSyntaxScope;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration;
import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.compiler.parser.UntypedAst.UntypedDeclaration;
import sillyscript.compiler.parser.UntypedAst.UntypedDictionaryEntry;
import sillyscript.MacroUtils.returnIfError;
import sillyscript.Positioned;

/**
	Used internally by `parseListOrDictionaryPostColonIdent` to track whether a list or dictionary 
	is being parsed.
**/
enum ParseKind {
	Unknown;
	List;
	Dictionary;
}

@:structInit
class ExpressionParserContext {
	public var parser(default, null): Parser;
	public var syntaxScope(default, null): Null<CustomSyntaxScope>;

	public function getOrMakeSyntaxScope(): CustomSyntaxScope {
		if(syntaxScope == null) {
			syntaxScope = new CustomSyntaxScope();
		}
		return syntaxScope;
	}
}

/**
	Handles the parsing of basic values, lists, and dictionaries in SillyScript.
**/
@:access(sillyscript.compiler.parser.Parser)
class ExpressionParser {
	/**
		Parses the contents of a list or dictionary as one would expect following a colon and
		incremented indent.
	**/
	public static function parseListOrDictionaryPostColonIdent(
		parser: Parser
	): ParseResult<Positioned<UntypedAst>> {
		var kind = Unknown;

		final context: ExpressionParserContext = {
			parser: parser,
			syntaxScope: null
		};

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
					switch(DefDeclParser.parseDef(parser)) {
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
				case Keyword(Syntax): {
					switch(CustomSyntaxDeclParser.parseCustomSyntaxDeclaration(parser)) {
						case Success(result): {
							declarations.push(result.map(cs -> CustomSyntax(cs)));
							context.getOrMakeSyntaxScope().addSyntaxDeclaration(result);
							continue;
						}
						case NoMatch: {}
						case Error(syntaxParserErrors): {
							for(e in syntaxParserErrors) {
								errors.push(e);
							}
							continue;
						}
					}
				}
				case _:
			}

			// Parse list or dictionary entry if all else fails...
			switch(parseListOrDictionaryEntry(context)) {
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
					errors.push({ value: ParserNoMatch, position: parser.here() });
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
				case Unknown: List({
					items: [], scope: { declarations: [], syntaxScope: null }
				});
				case List: List({
					items: listEntries, scope: { declarations: declarations, syntaxScope: context.syntaxScope }
				});
				case Dictionary: Dictionary({
					items: dictionaryEntries, scope: { declarations: declarations, syntaxScope: context.syntaxScope }
				});
			},
			position: parser.makePositionFrom(start)
		});
	}

	/**
		First attempts to parse: `<identifier>: <ast entry>`.
		If successful, it returns `Left`.

		If it cannot, it then attempts to parse: `<ast entry>` and returns `Right`.
	**/
	static function parseListOrDictionaryEntry(
		context: ExpressionParserContext
	): ParseResult<Either<Positioned<UntypedDictionaryEntry>, Positioned<UntypedAst>>> {
		switch(parseDictionaryEntry(context)) {
			case Success(result): return Success(Left(result));
			case Error(error): return Error(error);
			case _:
		}

		return parseExpression(context, false).map(null, (result) -> Either.Right(result));
	}

	/**
		Parses the following pattern: `<identifier>: <ast entry>`.
	**/
	static function parseDictionaryEntry(
		context: ExpressionParserContext
	): ParseResult<Positioned<UntypedDictionaryEntry>> {
		final parser = context.parser;

		final identifierToken = parser.peekWithPosition();
		if(identifierToken == null) return NoMatch;

		return switch(identifierToken.value) {
			case Identifier(content) if(parser.peek(1) == Colon): {
				parser.expectOrFatal(Identifier(content));
				parser.expectOrFatal(Colon);

				switch(parseExpression(context, true)) {
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
	public static function parseExpression(
		context: ExpressionParserContext,
		colonExists: Bool
	): ParseResult<Positioned<UntypedAst>> {
		final parser = context.parser;

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

			// Don't parse identifier until AFTER checking custom syntax.
			case Identifier(identifier): {
				NoMatch;
			}
			case _: {
				NoMatch;
			}
		}

		final syntaxScope = context.syntaxScope;
		final expression: ParseResult<Positioned<UntypedAst>> = switch(expression) {
			case NoMatch if(syntaxScope != null): {
				final state = parser.getState();
				final possibleSyntaxes = syntaxScope.matchSyntax(context, null);
				switch(possibleSyntaxes) {
					case Success(result): {
						final positionedUntypedAst: Positioned<UntypedAst> = {
							value: UntypedAst.CustomSyntax(result.possibilities, result.expressions),
							position: parser.makePositionFromState(state),
						};
						Success(positionedUntypedAst);
					}
					case NoMatch | Error(_): {
						parser.revertToState(state);
						NoMatch;
					}
				}
			}
			case _: expression;
		}

		final expression: ParseResult<Positioned<UntypedAst>> = switch(expression) {
			case NoMatch: {
				switch(firstToken.value) {
					case Identifier(identifier): {
						parser.advance();
						Success({
							value: Identifier(identifier),
							position: firstToken.position
						});
					}
					case _: expression;
				}
			}
			case _: expression;
		}

		return switch(expression) {
			case Success(innerExpression): {
				switch(parsePostExpression(context, innerExpression)) {
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
		context: ExpressionParserContext,
		expression: Positioned<UntypedAst>
	): ParseResult<Positioned<UntypedAst>> {
		final parser = context.parser;

		final firstToken = parser.peekWithPosition();
		if(firstToken == null) return NoMatch;

		final syntaxScope = context.syntaxScope;
		if(syntaxScope != null) {
			final state = parser.getState();
			final possibleSyntaxes = syntaxScope.matchSyntax(context, expression);
			switch(possibleSyntaxes) {
				case Success(result): {
					final positionedUntypedAst: Positioned<UntypedAst> = {
						value: UntypedAst.CustomSyntax(result.possibilities, result.expressions),
						position: parser.makePositionFromState(state),
					};

					// TODO, should we recursively call `parsePostExpression` on this result??
					return Success(positionedUntypedAst);
				}

				// Ignore errors and revert back to the original state.
				case NoMatch | Error(_): {
					parser.revertToState(state);
				}
			}
		}

		return switch(firstToken.value) {
			case ParenthesisOpen: {
				context.parser.expectOrFatal(ParenthesisOpen);
				parseCallArgumentsPostParenthesisOpen(context, expression);
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
		context: ExpressionParserContext,
		calledAst: Positioned<UntypedAst>
	): ParseResult<Positioned<UntypedAst>> {
		final parser = context.parser;

		function parseArgument() {
			final name = switch(parser.peek()) {
				case Identifier(identifier) if(parser.peek(1) == Colon): {
					parser.expectOrFatal(Identifier(identifier));
					parser.expectOrFatal(Colon);
					identifier;
				}
				case _: null;
			}

			return parseExpression(context, name != null).map(
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
