package sillyscript.compiler.executor;

import sillyscript.compiler.typer.SillyTypeKind;

/**
	All the possible errors that can occur during execution.
**/
enum ExecutorError {
	CompilerError(message: String);
	CannotExecuteDefIdentifier;
	CannotCallExpression;
	UnidentifiedDefArgumentIdentifier;
	CannotExecuteEmptyDef;
	CannotExecuteEnumOfType(kind: SillyTypeKind);
}
