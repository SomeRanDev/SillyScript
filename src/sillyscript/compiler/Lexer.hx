package sillyscript.compiler;

import sillyscript.Position.PositionKind;
using sillyscript.Error;

enum Token {
	Identifier(content: String);
	Keyword(keyword: Keyword);
	Null;
	Int(content: String);
	Float(content: String);
	String(content: String);
	Semicolon;
	Colon;
	Comma;
	Arrow;
	ExclamationPoint;
	ParenthesisOpen;
	ParenthesisClose;
	SquiggleOpen;
	SquiggleClose;
	SquareOpen;
	SquareClose;
	TriangleOpen;
	TriangleClose;
	IncrementIndent;
	DecrementIndent;
	Comment(content: String);
	MultilineComment(content: String);
	Other(character: String);
	EndOfFile;
}

enum Keyword {
	Def;
	Syntax;
}

enum LexifyResult {
	Success(tokens: Array<Token>);
	Error(errors: Array<{ error: ErrorKind, position: PositionKind }>);
}

class Lexer {
	var content: String;
	var filePath: Null<String>;
	var tokens: Array<Token>;
	var currentPosition: Int;
	var length: Int;
	var indentStack: Array<Int>;

	var errors: Array<{ error: ErrorKind, position: PositionKind }>;

	public function new(content: String, filePath: Null<String> = null) {
		this.content = content;
		this.filePath = filePath;

		tokens = [];
		currentPosition = 0;
		length = content.length;
		indentStack = [0];

		errors = [];
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
			indentStack.pop();
			tokens.push(Token.DecrementIndent);
		}

		tokens.push(Token.EndOfFile);
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
				error: UnexpectedEndOfFile,
				position: PositionKind.SingleCharacter(currentPosition)
			});
			return;
		}
		switch(c) {
			case " ", "\t": { handleSpace(); }
			case "\n", "\r": { advance(); }
			case ";": { handleSingleToken(Token.Semicolon); }
			case ":": { handleSingleToken(Token.Colon); }
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
			case "\"": { handleString(); }
			case "#": { handleComment(); }
			default: { handleComplexToken(c); }
		}
	}

	/**
		Pushes a single token and advances the seeker.
	**/
	function handleSingleToken(token: Token) {
		tokens.push(token);
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

		final indent = currentPosition - start;
		final prev = indentStack[indentStack.length - 1];
		if(indent > prev) {
			indentStack.push(indent);
			tokens.push(Token.IncrementIndent);
		} else if(indent < prev) {
			while(
				indentStack.length > 0 &&
				indentStack[indentStack.length - 1] > indent
			) {
				indentStack.pop();
				tokens.push(Token.DecrementIndent);
			}
		}
	}

	/**
		Processes a string.

		Should be called when `peek() == "\""`.
	**/
	function handleString() {
		var start = ++currentPosition;
		while(currentPosition < length && peek() != "\"") {
			if(peek() == "\\") {
				advance();
			}
			advance();
		}
		var str = content.substring(start, currentPosition);
		advance();
		tokens.push(Token.String(str));
	}

	/**
		Processes either a single or multiline comment.

		Should be called when `peek() == "#"`.
	**/
	function handleComment() {
		// Multiline comment...
		if(peek(1) == "#" && peek(2) == "#") {
			advance(3);
			var start = currentPosition;
			while(currentPosition < length - 2 && !(peek() == "#" && peek(1) == "#" && peek(2) == "#")) {
				advance();
			}
			var str = content.substring(start, currentPosition);
			advance(3);
			tokens.push(Token.MultilineComment(str));
			return;
		}

		// Single-line comment...
		advance();
		var start = currentPosition;
		while(currentPosition < length && peek() != "\n") {
			advance();
		}
		tokens.push(Token.Comment(content.substring(start, currentPosition)));
	}

	/**
		Handles a complicated token parse that cannot be ascertained from just the first character.
	**/
	function handleComplexToken(firstCharacter: String) {
		if(firstCharacter == "-" && peek(1) == ">") {
			tokens.push(Token.Arrow);
			advance(2);
		} else if(isDigit(firstCharacter)) {
			handleNumber();
		} else if(isIdentStart(firstCharacter)) {
			handleIdentifierOrKeyword();
		} else {
			tokens.push(Token.Other(firstCharacter));
			advance();
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
			tokens.push(Token.Float(content.substring(start, currentPosition)));
		} else {
			tokens.push(Token.Int(content.substring(start, currentPosition)));
		}
	}

	/**
		Processes an identifier or keyword.

		Should be called when `isIdentStart(peek()) == true`.
	**/
	function handleIdentifierOrKeyword() {
		final start = currentPosition;

		// Parse identifier
		var currentChar = peek();
		while(currentChar != null && isIdentPart(currentChar)) {
			advance();
			currentChar = peek();
		}

		switch(content.substring(start, currentPosition)) {
			case "null": tokens.push(Token.Null);
			case "def": tokens.push(Token.Keyword(Def));
			case "syntax": tokens.push(Token.Keyword(Syntax));
			case identifier: tokens.push(Token.Identifier(identifier));
		}
	}
}