package sillyscript.compiler.typer;

import sillyscript.Position.Positioned;
import sillyscript.compiler.Value;

/**
	Typed syntax tree.
**/
enum TypedAst {
	Value(value: Value);
	List(items: Array<Positioned<TypedAst>>);
	Dictionary(items: Array<Positioned<{ key: Positioned<String>, value: Positioned<TypedAst> }>>);
	Placeholder;
}
