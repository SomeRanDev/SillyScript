package sillyscript.compiler.parser;

import sillyscript.compiler.lexer.Token;

enum ParserError {
	NoMatch;
	Expected(token: Token);
	ExpectedMultiple(tokens: Array<Token>);
	ExpectedValue;
	ExpectedListOrDictionaryEntries;
	UnexpectedListEntryWhileParsingDictionary;
	UnexpectedDictionaryEntryWhileParsingList;
}
