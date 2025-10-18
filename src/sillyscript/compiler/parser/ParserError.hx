package sillyscript.compiler.parser;

import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration.CustomSyntaxId;
import sillyscript.compiler.typer.SillyTypeKind;
import sillyscript.compiler.lexer.Token;

/**
	All the possible errors that can occur during parsing.
**/
enum ParserError {
	CompilerError(message: String);
	ParserNoMatch;
	Expected(token: Token);
	ExpectedMultiple(tokens: Array<Token>);
	ExpectedExpression;
	ExpectedType;
	ExpectedListOrDictionaryEntries;
	UnexpectedEndOfTokens;
	UnexpectedListEntryWhileParsingDictionary;
	UnexpectedDictionaryEntryWhileParsingList;
	TypeCannotHaveSubtype(typeKind: SillyTypeKind);
	UnknownSyntaxName(name: String);
	AmbiguousCustomSyntaxInCustomSyntax(customSyntaxIds: Array<CustomSyntaxId>);
}
