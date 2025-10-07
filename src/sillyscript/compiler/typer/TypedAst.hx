package sillyscript.compiler.typer;

import sillyscript.compiler.typer.subtyper.DefTyper.TypedDef;
import sillyscript.compiler.typer.Scope;
import sillyscript.Positioned;
import sillyscript.compiler.Value;

/**
	Typed syntax tree.
**/
enum TypedAst {
	Value(value: Value);
	List(items: Array<Positioned<TypedAst>>, scope: Scope);
	Dictionary(items: Array<Positioned<{ key: Positioned<String>, value: Positioned<TypedAst> }>>, scope: Scope);
	DefIdentifier(typedDef: Positioned<TypedDef>);
	DefArgumentIdentifier(typedDef: Positioned<TypedDef>, argumentIndex: Int);
	Call(calledAst: Positioned<TypedAst>, arguments: Array<Positioned<TypedAst>>);
}
