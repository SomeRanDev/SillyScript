package sillyscript.compiler.parser;

import sillyscript.compiler.typer.Type.TypeKind;
import sillyscript.compiler.lexer.Token;

enum ParserError {
	NoMatch;
	Expected(token: Token);
	ExpectedMultiple(tokens: Array<Token>);
	ExpectedExpression;
	ExpectedType;
	ExpectedListOrDictionaryEntries;
	UnexpectedListEntryWhileParsingDictionary;
	UnexpectedDictionaryEntryWhileParsingList;
	TypeCannotHaveSubtype(typeKind: TypeKind);
}
