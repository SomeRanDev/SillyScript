package sillyscript.compiler.typer;

/**
	Joins together a `TypedAst` and its `SillyType`.
**/
typedef TypedAstWithType = {
	typedAst: Positioned<TypedAst>,
	type: SillyType
};
