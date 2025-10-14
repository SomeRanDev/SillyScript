package sillyscript.compiler.typer.ast;

import sillyscript.compiler.typer.ast.TypedDef;
import sillyscript.Positioned;

/**
	A representation of what an identifier can be post-typing.
**/
enum TypedIdentifier {
	Def(def: Positioned<TypedDef>);
	DefArgument(def: Positioned<TypedDef>, index: Int);
}
