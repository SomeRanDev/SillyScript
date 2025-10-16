package sillyscript.compiler.lexer;

import sillyscript.extensions.Stack;
import sillyscript.compiler.lexer.LexerError;
import sillyscript.compiler.lexer.Token;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.Position;
using sillyscript.extensions.StringExt;

typedef LexifyResult = PositionedResult<Array<Positioned<Token>>, LexerError>;

class Lexer {
	var content: String;
	var fileIdentifier: Int;
	var tokens: Array<Positioned<Token>>;
	var currentPosition: Int;
	var length: Int;
	var indentStack: Stack<Int>;

	var errors: Array<Positioned<LexerError>>;

	public function new(content: String, fileIdentifier: Int) {
		this.content = content;
		this.fileIdentifier = fileIdentifier;

		tokens = [];
		currentPosition = 0;
		length = content.length;
		indentStack = [0];

		errors = [];
	}

	/**
		Generates a `Position` from `start` to `end` inclusive.
	**/
	function makePosition(start: Int, end: Int): Position {
		return { fileIdentifier: fileIdentifier, start: start, end: end + 1 };
	}

	/**
		Creates a `Position` starting from `start` and ending at `currentPosition`.
	**/
	inline function makePositionFrom(start: Int): Position {
		return makePosition(start, currentPosition);
	}

	/**
		Creates a `Position` that points to a single character at `position`.
	**/
	inline function makeSingleCharacterPosition(position: Int): Position {
		return makePosition(position, position + 1);
	}

	public function lexify(): LexifyResult {
		while(currentPosition < length) {
			processNextCharacter();
		}

		if(errors.length > 0) {
			return Error(errors);
		}

		// close any remaining indents
		while(indentStack.length > 1) {
			indentStack.popTop();
			tokens.push({
				value: Token.DecrementIndent,
				position: makeSingleCharacterPosition(length)
			});
		}

		tokens.push({ value: Token.EndOfFile, position: makeSingleCharacterPosition(length) });
		return Success(tokens);
	}

	inline function peek(offset: Int = 0): Null<String> {
		return currentPosition + offset < length ? content.charAt(currentPosition + offset) : null;
	}

	inline function advance(n: Int = 1) {
		currentPosition += n;
	}

	inline function atLineStart(pos: Int): Bool {
		return pos == 0 || content.charAt(pos - 1) == "\n";
	}

	static inline function isAlpha(ch: String): Bool {
		if(ch == null || ch.length != 1) {
			return false;
		}
		final code = ch.charCodeAt(0);
		if(code == null) {
			return false;
		}
		return (
			(code >= 'a'.code && code <= 'z'.code) ||
			(code >= 'A'.code && code <= 'Z'.code)
		);
	}

	static inline function isDigit(ch: String): Bool {
		if(ch == null || ch.length != 1) {
			return false;
		}
		final code = ch.charCodeAt(0);
		if(code == null) {
			return false;
		}
		return code >= '0'.code && code <= '9'.code;
	}

	static inline function isIdentStart(ch: String): Bool {
		return isAlpha(ch) || ch == "_";
	}

	static inline function isIdentPart(ch: String): Bool {
		return isAlpha(ch) || isDigit(ch) || ch == "_";
	}

	function processNextCharacter() {
		var c = peek();
		if(c == null) {
			errors.push({
				value: UnexpectedEndOfFile,
				position: makeSingleCharacterPosition(currentPosition)
			});
			return;
		}
		switch(c) {
			case " ", "\t": { handleSpace(); }
			case "\r": { advance(); }
			case "\n": { advance(); handleSpace(); }
			case ";": { handleSingleToken(Token.Semicolon); }
			case ":": { handleSingleToken(Token.Colon); }
			case "=": { handleSingleToken(Token.Equals); }
			case "(": { handleSingleToken(Token.ParenthesisOpen); }
			case ")": { handleSingleToken(Token.ParenthesisClose); }
			case "{": { handleSingleToken(Token.SquiggleOpen); }
			case "}": { handleSingleToken(Token.SquiggleClose); }
			case "[": { handleSingleToken(Token.SquareOpen); }
			case "]": { handleSingleToken(Token.SquareClose); }
			case "<": { handleSingleToken(Token.TriangleOpen); }
			case ">": { handleSingleToken(Token.TriangleClose); }
			case ",": { handleSingleToken(Token.Comma); }
			case "!": { handleSingleToken(Token.ExclamationPoint); }
			case "?": { handleSingleToken(Token.QuestionMark); }
			case "\"": { handleString(); }
			case "#": { handleComment(); }
			default: { handleComplexToken(c); }
		}
	}

	/**
		Pushes a single token and advances the seeker.
	**/
	function handleSingleToken(token: Token) {
		tokens.push({ value: token, position: makeSingleCharacterPosition(currentPosition) });
		advance();
	}

	/**
		Processes a space or tab character.

		Should be called when `peek() == " "` or `peek() == "\t"`.
	**/
	function handleSpace() {
		// If not at the start of the line, just ignore it...
		if(!atLineStart(currentPosition)) {
			advance();
			return;
		}

		final start = currentPosition;
		var character = peek();
		while(character == " " || character == "\t") {
			advance();
			character = peek();
		}

		// If the line only contains spaces, ignore it...
		if(character == "\n" || character == "\r") {
			return;
		}

		final indent = currentPosition - start;
		final prev = indentStack.last();
		if(indent > prev) {
			indentStack.pushTop(indent);
			tokens.push({
				value: Token.IncrementIndent,
				position: makePositionFrom(start)
			});
		} else if(indent < prev) {
			while(
				indentStack.length > 0 &&
				indentStack.last() > indent
			) {
				indentStack.popTop();
				tokens.push({
					value: Token.DecrementIndent,
					position: makePosition(start, currentPosition - 1),
				});
			}
		}
	}

	/**
		Processes a string.

		Should be called when `peek() == "\""`.
	**/
	function handleString() {
		final stringStart = currentPosition;
		advance();

		final stringContentStart = currentPosition;
		while(currentPosition < length && peek() != "\"") {
			if(peek() == "\\") {
				advance();
			}
			advance();
		}

		final stringContent = content.substring(stringContentStart, currentPosition);
		advance();

		tokens.push({
			value: Token.String(stringContent),
			position: makePositionFrom(stringStart)
		});
	}

	/**
		Processes either a single or multiline comment.

		Should be called when `peek() == "#"`.
	**/
	function handleComment() {
		// Multiline comment...
		if(peek(1) == "#" && peek(2) == "#") {
			final commentStart = currentPosition;
			advance(3);

			final commentContentStart = currentPosition;
			while(currentPosition < length - 2 && !(peek() == "#" && peek(1) == "#" && peek(2) == "#")) {
				advance();
			}

			final commentContent = content.substring(commentContentStart, currentPosition);
			advance(3);

			tokens.push({
				value: Token.MultilineComment(commentContent),
				position: makePositionFrom(commentStart)
			});

			return;
		}

		// Single-line comment...
		final commentStart = currentPosition;
		advance();

		final commentContentStart = currentPosition;
		while(currentPosition < length && peek() != "\n") {
			advance();
		}

		tokens.push({
			value: Token.Comment(content.substring(commentContentStart, currentPosition)),
			position: makePositionFrom(commentStart)
		});
	}

	/**
		Handles a complicated token parse that cannot be ascertained from just the first character.
	**/
	function handleComplexToken(firstCharacter: String) {
		if(firstCharacter == "-" && peek(1) == ">") {
			advance(2);
			tokens.push({
				value: Token.Arrow,
				position: makePosition(currentPosition - 2, currentPosition - 1)
			});
		} else if(isDigit(firstCharacter)) {
			handleNumber();
		} else if(isIdentStart(firstCharacter)) {
			handleIdentifierOrKeyword();
		} else {
			advance();
			tokens.push({
				value: Token.Other(firstCharacter),
				position: makeSingleCharacterPosition(currentPosition - 1)
			});
		}
	}

	/**
		Processes an int or float literal.

		Should be called when `isDigit(peek()) == true`.
	**/
	function handleNumber() {
		function parseDigits() {
			var currentChar = peek();
			while(currentChar != null && isDigit(currentChar)) {
				advance();
				currentChar = peek();
			}
		}

		final start = currentPosition;
		parseDigits();
		if(peek() == ".") {
			advance();
			parseDigits();
			tokens.push({
				value: Token.Float(content.substring(start, currentPosition)),
				position: makePositionFrom(start)
			});
		} else {
			tokens.push({
				value: Token.Int(content.substring(start, currentPosition)),
				position: makePositionFrom(start)
			});
		}
	}

	/**
		Processes an identifier or keyword.

		Should be called when `isIdentStart(peek()) == true`.
	**/
	function handleIdentifierOrKeyword() {
		final start = currentPosition;

		var currentChar = peek();
		while(currentChar != null && isIdentPart(currentChar)) {
			advance();
			currentChar = peek();
		}

		final tokenKind = switch(content.substring(start, currentPosition)) {
			case "null": Token.Null;
			case "true": Token.Bool(true);
			case "false": Token.Bool(false);
			case "def": Token.Keyword(Def);
			case "enum": Token.Keyword(Enum);
			case "syntax": Token.Keyword(Syntax);
			case "pattern": Token.Keyword(Pattern);
			case identifier: Token.Identifier(identifier);
		}

		tokens.push({
			value: tokenKind,
			position: makePositionFrom(start)
		});
	}
}