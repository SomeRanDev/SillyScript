package sillyscript.compiler.lexer;

enum Keyword {
	Def;
	Syntax;
}

@:using(sillyscript.compiler.lexer.Token.TokenExt)
enum Token {
	Identifier(content: String);
	Keyword(keyword: Keyword);
	Null;
	Bool(value: Bool);
	Int(content: String);
	Float(content: String);
	String(content: String);
	Semicolon;
	Colon;
	Comma;
	Arrow;
	ExclamationPoint;
	QuestionMark;
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

class TokenExt {
	public static function equals(self: Token, other: Token) {
		if(Type.enumIndex(self) != Type.enumIndex(other)) {
			return false;
		}

		return switch([self, other]) {
			case
				[Identifier(selfContent), Identifier(otherContent)] |
				[Int(selfContent), Int(otherContent)] |
				[Float(selfContent), Float(otherContent)] |
				[String(selfContent), String(otherContent)] |
				[Comment(selfContent), Comment(otherContent)] |
				[MultilineComment(selfContent), MultilineComment(otherContent)] |
				[Other(selfContent), Other(otherContent)]
			: selfContent == otherContent;

			case [Keyword(selfKeyword), Keyword(otherKeyword)]: selfKeyword == otherKeyword;

			case [Bool(selfBool), Bool(otherBool)]: selfBool == otherBool;

			case _: true;
		}
	}
}
