package sillyscript.compiler.executor;

/**
	All the possible errors that can occur during execution.
**/
enum ExecutorError {
	CannotExecuteDefIdentifier;
	CannotCallExpression;
	UnidentifiedDefArgumentIdentifier;
	CannotExecuteEmptyDef;
}
