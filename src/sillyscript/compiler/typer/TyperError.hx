package sillyscript.compiler.typer;

import sillyscript.compiler.typer.subtyper.DefTyper.TypedDef;

enum TyperError {
	NothingWithName(name: String);
	MissingArgument(def: TypedDef, argumentIndex: Int);
	CannotCallExpression;
}
