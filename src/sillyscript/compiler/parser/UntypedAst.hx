package sillyscript.compiler.parser;

import sillyscript.compiler.parser.subparsers.DefParser.UntypedDef;
import sillyscript.Positioned;

typedef UntypedDictionaryEntry = { key: Positioned<String>, value: Positioned<UntypedAst> };

/**
	Untyped syntax tree.
**/
enum UntypedAst {
	Identifier(name: String);
	Value(value: Value);
	List(items: Array<Positioned<UntypedAst>>, declarations: Array<Positioned<UntypedDeclaration>>);
	Dictionary(items: Array<Positioned<UntypedDictionaryEntry>>, declarations: Array<Positioned<UntypedDeclaration>>);
	Call(calledAst: Positioned<UntypedAst>, arguments: Array<{ name: Null<String>, value: Positioned<UntypedAst> }>);
}

enum UntypedDeclaration {
	Def(def: UntypedDef);
}
