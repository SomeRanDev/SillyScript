package sillyscript.compiler.parser;

import sillyscript.compiler.parser.subparsers.ExpressionParser;
import haxe.CallStack;
import haxe.ds.Either;
import sillyscript.compiler.lexer.Token;
import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.compiler.Value;
import sillyscript.Positioned;
using sillyscript.extensions.ArrayExt;

typedef ParserState = {
	index: Int,
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
		Get the current state of the parser.
	**/
	public function getState(): ParserState {
		return {
			index: currentIndex
		};
	}

	/**
		Sets the state of the parser to a previous state.
	**/
	public function revertToState(oldState: ParserState) {
		currentIndex = oldState.index;
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
		Creates a `Position` starting from state obtained from `getState`.
	**/
	inline function makePositionFromState(state: ParserState): Position {
		return makePosition(state.index, currentIndex);
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
	public inline function peek(offset: Int = 0): Null<Token> {
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
	public inline function advance(n: Int = 1) {
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
			final callstack = CallStack.toString(CallStack.callStack());
			#if (sys || hxnodejs) Sys.println #else trace #end(callstack);
			throw "Unexpected token encountered. This is an error, please report!";
		}
	}

	/**
		Begins parsing the `inputTokens` provided in the constructor.
	**/
	public function parse(): ParseResult<Positioned<UntypedAst>> {
		return ExpressionParser.parseListOrDictionaryPostColonIdent(this);
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
}