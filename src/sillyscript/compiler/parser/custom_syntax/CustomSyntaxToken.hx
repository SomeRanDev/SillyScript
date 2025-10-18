package sillyscript.compiler.parser.custom_syntax;

import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration.CustomSyntaxId;
import sillyscript.compiler.lexer.Token;

/**
	Represents a token in a custom syntax.
	It can either be a single character token OR an expression that the syntax contains.
**/
@:using(sillyscript.compiler.parser.custom_syntax.CustomSyntaxToken.CustomSyntaxTokenExt)
enum CustomSyntaxToken {
	Expression;
	Token(token: Token);
}

/**
	Functions for `CustomSyntaxToken`.
**/
class CustomSyntaxTokenExt {
	/**
		Checks if the two `CustomSyntaxToken` values are identical.
	**/
	public static function isEqual(self: CustomSyntaxToken, other: CustomSyntaxToken) {
		return switch(self) {
			case Expression: {
				switch(other) {
					case Expression: true;
					case _: false;
				}
			}
			case Token(token1): {
				switch(other) {
					case Token(token2): token1.equals(token2);
					case _: false;
				}
			}
		}
	}
}
