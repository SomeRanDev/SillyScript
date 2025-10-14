package sillyscript.compiler.parser;

import sillyscript.compiler.typer.SillyTypeKind;
import sillyscript.compiler.lexer.Token;

/**
	All the possible errors that can occur during parsing.
**/
enum ParserError {
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
}
