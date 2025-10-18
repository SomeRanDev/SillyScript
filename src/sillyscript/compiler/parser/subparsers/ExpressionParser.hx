package sillyscript.compiler.parser.subparsers;

import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration.UntypedCustomSyntaxDeclarationPattern;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration.CustomSyntaxId;
import haxe.ds.Either;
import sillyscript.compiler.parser.custom_syntax.CustomSyntaxScope;
import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.compiler.parser.subparsers.DefDeclParser;
import sillyscript.compiler.parser.UntypedAst.UntypedDeclaration;
import sillyscript.compiler.parser.UntypedAst.UntypedDictionaryEntry;
import sillyscript.MacroUtils.returnIfError;
import sillyscript.MacroUtils.returnIfErrorWith;
import sillyscript.Positioned;
using sillyscript.extensions.ArrayExt;

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

	var stackSize: Int = 0;

	public function getOrMakeSyntaxScope(): CustomSyntaxScope {
		if(syntaxScope == null) {
			syntaxScope = new CustomSyntaxScope();
		}
		return syntaxScope;
	}

	public function pushStack() {
		if(syntaxScope != null) {
			syntaxScope.pushScope();
			stackSize++;
		}
	}

	public function popStack() {
		if(syntaxScope != null && stackSize > 0) {
			syntaxScope.popScope();
			stackSize--;
		}
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
		context: ExpressionParserContext
	): ParseResult<Positioned<UntypedAst>> {
		final parser = context.parser;

		var kind = Unknown;

		// final context: ExpressionParserContext = {
		// 	parser: parser,
		// 	syntaxScope: null
		// };
		context.pushStack();

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
					switch(DefDeclParser.parseDef(context)) {
						case Success(result): {
							declarations.push(result.map(d -> Def(d)));
							continue;
						}
						case NoMatch: {}
						case Error(defParserErrors): {
							errors.pushArray(defParserErrors);
							continue;
						}
					}
				}
				case Keyword(Enum): {
					switch(EnumDeclParser.parseEnum(parser)) {
						case Success(result): {
							declarations.push(result.map(d -> Enum(d)));
							continue;
						}
						case NoMatch: {}
						case Error(enumParserErrors): {
							errors.pushArray(enumParserErrors);
							continue;
						}
					}
				}
				case Keyword(Syntax): {
					switch(CustomSyntaxDeclParser.parseCustomSyntaxDeclaration(context)) {
						case Success(result): {
							declarations.push(result.map(cs -> CustomSyntax(cs)));
							context.getOrMakeSyntaxScope().addSyntaxDeclaration(result);
							continue;
						}
						case NoMatch: {}
						case Error(syntaxParserErrors): {
							errors.pushArray(syntaxParserErrors);
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
					errors.pushArray(entryParseErrors);
					break;
				}
			}

			if(parser.peek(-1) != DecrementIndent) {
				returnIfErrorWith(parser.expect(Semicolon), errors);
			}
		}

		context.popStack();

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
			position: parser.makePositionFrom(start, false)
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
				parseListOrDictionaryPostColonIdent(context).map(
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
				parseListOrDictionaryPostColonIdent(context).map(
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
							position: parser.makePositionFromState(state, false),
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

	/**
		Parse content after an expression has been parsed.

		Currently this checks for any custom syntax that starts with an expression input.
		If that fails, it checks for a "call" to a definition.
	**/
	static function parsePostExpression(
		context: ExpressionParserContext,
		expression: Positioned<UntypedAst>
	): ParseResult<Positioned<UntypedAst>> {
		final parser = context.parser;

		final firstToken = parser.peekWithPosition();
		if(firstToken == null) return NoMatch;

		switch(parseCustomSyntaxPostExpression(context, expression)) {
			case Success(result): return Success(result);
			case NoMatch: {}
			case Error(e): return Error(e);
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
		Attempt to parse a custom syntax after an expression has been parsed.
	**/
	static function parseCustomSyntaxPostExpression(
		context: ExpressionParserContext,
		expression: Positioned<UntypedAst>
	): ParseResult<Positioned<UntypedAst>> {
		final parser = context.parser;
		final syntaxScope = context.syntaxScope;
		if(syntaxScope == null) return NoMatch;

		final startingState = parser.getState();
		final possibleSyntaxes = syntaxScope.matchSyntax(context, expression);
		switch(possibleSyntaxes) {
			case Success(result): {
				// If `expression` is a `CustomSyntax` with all candidates of a single ID,
				// that ID is stored here. Otherwise, this value will be `-1`.
				final inputExpressionSyntaxId: CustomSyntaxId = switch(expression.value) {
					case CustomSyntax(candidates, _): {
						var candidateId: CustomSyntaxId = -1;
						for(c in candidates) {
							if(candidateId == -1) {
								candidateId = c.id;
							} else if(candidateId != c.id) {
								candidateId = -1;
								break;
							}
						}
						candidateId;
					}
					case _: -1;
				}

				// Filter the possibilities so that if an input REQUIRES a custom syntax, but its
				// provided expression is NOT a custom syntax of the same ID, it gets removed.
				//
				// This helps resolve parsing problems for post-fix custom syntax that is too
				// greedy.
				//
				// syntax Temp:
				//     pattern
				//          say <input: string>
				//
				//     pattern:
				//         <something: syntax!Temp>?
				//
				// # The question will be consumed by the postfix parse of `"Test"` instead of
				// # `say "Test"` if we do not filter possibilities here.
				// say "Test"?;
				final newPossibilities = [];
				for(possibility in result.possibilities) {
					final pattern: Null<UntypedCustomSyntaxDeclarationPattern> = syntaxScope
						.findSyntaxDeclarationById(possibility.id)
						?.value
						?.patterns[possibility.patternIndex];
					final isPossibilityAllowed = if(pattern != null && pattern.tokenPattern.length > 0) {
						switch(pattern.tokenPattern[0]) {
							case ExpressionInput(name, type): {
								switch(type.value) {
									case CustomSyntaxInput(id): inputExpressionSyntaxId == id;
									case _: true;
								}
							}
							case _: true;
						}
					} else {
						true;
					}

					if(isPossibilityAllowed) {
						newPossibilities.push(possibility);
					}
				}

				// If `newPossibilities` DID filter stuff, remake `result` here!
				if(newPossibilities.length != result.possibilities.length) {
					result = {
						possibilities: newPossibilities,
						expressions: result.expressions
					};
				}

				// If any possibilities remain, successfully generate the custom syntax and run
				// `parsePostExpression` on THAT to handle additional postfix stuff afterwards!
				if(result.possibilities.length > 0) {
					final positionedUntypedAst: Positioned<UntypedAst> = {
						value: UntypedAst.CustomSyntax(result.possibilities, result.expressions),
						position: parser.makePositionFromState(startingState, false),
					};

					return switch(parsePostExpression(context, positionedUntypedAst)) {
						case Success(result): Success(result);
						case NoMatch: Success(positionedUntypedAst);
						case Error(e): Error(e);
					}
				}
			}

			// Ignore errors and revert back to the original state after switch statement.
			case NoMatch | Error(_): {}
		}

		// The parse was not successful, but tokens were consumed, so let's revert back to the state
		// at the start of the function.
		parser.revertToState(startingState);

		return NoMatch;
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
			position: parser.makePositionFrom(start, false)
		});
	}
}
