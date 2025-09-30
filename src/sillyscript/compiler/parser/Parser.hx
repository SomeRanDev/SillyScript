package sillyscript.compiler.parser;

import haxe.CallStack;
import haxe.ds.Either;
import sillyscript.compiler.lexer.Token;
import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.compiler.Value;
import sillyscript.MacroUtils.returnIfError;
import sillyscript.Position.Positioned;
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

/**
	Parses the untyped AST from tokens.
**/
class Parser {
	var inputTokens: Array<Positioned<Token>>;
	var context: Context;

	var currentIndex: Int;

	var errors: Array<Positioned<ParserError>>;

	/**
		Constructor.
	**/
	public function new(inputTokens: Array<Positioned<Token>>, context: Context) {
		this.inputTokens = inputTokens.filter(function(t) {
			return switch(t.value) {
				case Comment(_) | MultilineComment(_): false;
				case _: true;
			}
		});
		this.context = context;

		currentIndex = 0;
		errors = [];
	}

	/**
		Generates a `Position` from `start` to `end` inclusive.
	**/
	function makePosition(start: Int, end: Int): Position {
		final startToken = inputTokens.get(start);
		final endToken = inputTokens.get(end);
		return if(startToken != null && endToken != null) {
			startToken.position.merge(endToken.position);
		} else {
			startToken?.position ?? endToken?.position ?? { fileIdentifier: -1, start: -1, end: -1 };
		}
	}

	/**
		Creates a `Position` starting from `start` and ending at `currentIndex`.
	**/
	inline function makePositionFrom(start: Int): Position {
		return makePosition(start, currentIndex);
	}

	/**
		Creates a `Position` that points to a single character at `position`.
	**/
	inline function makeSingleCharacterPosition(position: Int): Position {
		return makePosition(position, position + 1);
	}

	/**
		Returns the current position of the parser.
	**/
	inline function here(): Position {
		final t = peekWithPosition();
		return if(t != null) {
			t.position;
		} else {
			makeSingleCharacterPosition(currentIndex);
		}
	}

	/**
		Returns the current `Token` if it exists.

		`offset` can be defined to check ahead or behind.
	**/
	inline function peek(offset: Int = 0): Null<Token> {
		final index = currentIndex + offset;
		return if(index >= 0 && index < inputTokens.length) {
			inputTokens.get(index)?.value;
		} else {
			null;
		}
	}

	/**
		Returns the current `Token` if it exists.

		`offset` can be defined to check ahead or behind.
	**/
	inline function peekWithPosition(offset: Int = 0): Null<Positioned<Token>> {
		final index = currentIndex + offset;
		return if(index >= 0 && index < inputTokens.length) {
			inputTokens.get(index);
		} else {
			null;
		}
	}

	/**
		Advances the `currentIndex` by `n`.
	**/
	inline function advance(n: Int = 1) {
		currentIndex += n;
	}

	/**
		Advances by one, but only if the current token is `token`.
	**/
	inline function expect(token: Token): Null<Positioned<ParserError>> {
		final t = peek();
		return if(t != null && t.equals(token)) {
			advance();
			null;
		} else {
			{ value: Expected(token), position: here() };
		}
	}

	/**
		Advances by one, but only if the current token is `token`.
		If not, then nothing happens.
	**/
	inline function advanceIfMatch(token: Token) {
		final t = peek();
		if(t != null && t.equals(token)) {
			advance();
		}
	}

	/**
		Advances by one, but only if the current token is `token`.
		Throws a fatal error if the token does not match.
	**/
	inline function expectOrFatal(token: Token) {
		final t = peek();
		if(t != null && t.equals(token)) {
			advance();
		} else {
			trace(CallStack.toString(CallStack.callStack()));
			throw "Unexpected token encountered. This is an error, please report!";
		}
	}

	/**
		Begins parsing the `inputTokens` provided in the constructor.
	**/
	public function parse(): ParseResult<Positioned<UntypedAst>> {
		return parseListOrDictionaryPostColonIdent();
	}

	/**
		Increments `currentIndex` until the current token is a semicolon or the end of the file.
	**/
	function goToNextSemicolon() {
		final start = currentIndex;
		var c = peek();
		while(c != Semicolon && c != EndOfFile) {
			advance();
			c = peek();
		}
		return currentIndex - start;
	}

	/**
		Increments `currentIndex` until the current token isn't whitespace.
	**/
	function ignoreWhitespace() {
		final start = currentIndex;
		var c = peek();
		while(c == IncrementIndent || c == DecrementIndent) {
			advance();
			c = peek();
		}
		return currentIndex - start;
	}

	/**
		Parses the contents of a list or dictionary as one would expect following a colon and
		incremented indent.
	**/
	function parseListOrDictionaryPostColonIdent(): ParseResult<Positioned<UntypedAst>> {
		var kind = Unknown;

		final start = currentIndex;
		final listEntries: Array<Positioned<UntypedAst>> = [];
		final dictionaryEntries: Array<Positioned<{ key: Positioned<String>, value: Positioned<UntypedAst> }>> = [];
		final errors: Array<Positioned<ParserError>> = [];

		var c = peek();
		while(c != DecrementIndent && c != EndOfFile) {
			switch(parseListOrDictionaryEntry()) {
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
				case NoMatch: return NoMatch;
				case Error(error): return Error(error);
			}

			if(peek(-1) != DecrementIndent) {
				returnIfError(expect(Semicolon));
			}

			c = peek();
		}

		if(errors.length > 0) {
			return Error(errors);
		}

		return Success({
			value: switch(kind) {
				case Unknown: List([]);
				case List: List(listEntries);
				case Dictionary: Dictionary(dictionaryEntries);
			},
			position: makePositionFrom(start)
		});
	}

	/**
		First attempts to parse: `<identifier>: <ast entry>`.
		If successful, it returns `Left`.

		If it cannot, it then attempts to parse: `<ast entry>` and returns `Right`.
	**/
	function parseListOrDictionaryEntry(): ParseResult<Either<
		Positioned<{ key: Positioned<String>, value: Positioned<UntypedAst> }>,
		Positioned<UntypedAst>
	>> {
		switch(parseDictionaryEntry()) {
			case Success(result): return Success(Left(result));
			case Error(error): return Error(error);
			case _:
		}

		return parseAstEntry(false).map(null, (result) -> Either.Right(result));
	}

	/**
		Parses the following pattern: `<identifier>: <ast entry>`.
	**/
	function parseDictionaryEntry(): ParseResult<Positioned<{
		key: Positioned<String>,
		value: Positioned<UntypedAst>
	}>> {
		final identifierToken = peekWithPosition();
		if(identifierToken == null) return NoMatch;

		return switch(identifierToken.value) {
			case Identifier(content) if(peek(1) == Colon): {
				expectOrFatal(Identifier(content));
				expectOrFatal(Colon);

				switch(parseAstEntry(true)) {
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
					case NoMatch: Error([{ value: ExpectedValue, position: here() }]);
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
	function parseAstEntry(colonExists: Bool): ParseResult<Positioned<UntypedAst>> {
		final firstToken = peekWithPosition();
		if(firstToken == null) return Error([{ value: ExpectedValue, position: here() }]);

		final simpleEntry = switch(firstToken.value) {
			case Null: Null;
			case Bool(value): Bool(value);
			case Int(content): Int(content);
			case Float(content): Float(content);
			case String(content): String(content);
			case _: null;
		}

		if(simpleEntry != null) {
			advance();
			return Success({
				value: Value(simpleEntry),
				position: firstToken.position
			});
		}

		return switch(firstToken.value) {
			case IncrementIndent if(colonExists): {
				expectOrFatal(IncrementIndent);
				parseListOrDictionaryPostColonIdent().map(
					{ value: ExpectedListOrDictionaryEntries, position: here() },
					function(result) {
						advanceIfMatch(DecrementIndent);
						return result;
					}
				);
			}
			case Colon if(!colonExists && peek(1) == IncrementIndent): {
				expectOrFatal(Colon);
				expectOrFatal(IncrementIndent);
				parseListOrDictionaryPostColonIdent().map(
					{ value: ExpectedListOrDictionaryEntries, position: here() },
					function(result) {
						advanceIfMatch(DecrementIndent);
						return result;
					}
				);
			}
			case Identifier(identifier) if(peek(1) == ParenthesisOpen): {
				expectOrFatal(Identifier(identifier));
				expectOrFatal(ParenthesisOpen);
				parseCallArgumentsPostParenthesisOpen(identifier);
			}
			case _: NoMatch;
		}
	}

	/**
		Parses the contents of call arguments after the opening parenthesis is parsed.
	**/
	function parseCallArgumentsPostParenthesisOpen(identifier: String): ParseResult<Positioned<UntypedAst>> {
		function parseArgument() {
			final name = switch(peek()) {
				case Identifier(identifier) if(peek(1) == Colon): {
					expectOrFatal(Identifier(identifier));
					expectOrFatal(Colon);
					identifier;
				}
				case _: null;
			}

			return parseAstEntry(name != null).map(
				{
					value: ExpectedValue,
					position: here()
				},
				function(ast) {
					return { name: name, value: ast };
				}
			);
		}

		final start = currentIndex - 1; // Including previous token (open parenthesis).

		ignoreWhitespace();

		final arguments = [];
		while(peek() != ParenthesisClose) {
			switch(parseArgument()) {
				case Success(result): arguments.push(result);
				case NoMatch: {}
				case Error(error): return Error(error);
			}

			ignoreWhitespace();

			switch(peek()) {
				case Comma: expectOrFatal(Comma);
				case ParenthesisClose: {}
				case _: return Error([{
					value: ExpectedMultiple([Comma, ParenthesisClose]),
					position: here()
				}]);
			}

			ignoreWhitespace();
		}

		expectOrFatal(ParenthesisClose);
		
		return Success({
			value: Call(identifier, arguments),
			position: makePositionFrom(start)
		});
	}
}