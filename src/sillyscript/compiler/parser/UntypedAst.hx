package sillyscript.compiler.parser;

import sillyscript.Position.Positioned;

/**
	Untyped syntax tree.
**/
enum UntypedAst {
	Value(value: Value);
	List(items: Array<Positioned<UntypedAst>>);
	Dictionary(items: Array<Positioned<{ key: Positioned<String>, value: Positioned<UntypedAst> }>>);
	Call(identifier: String, arguments: Array<{ name: Null<String>, value: Positioned<UntypedAst> }>);
}
