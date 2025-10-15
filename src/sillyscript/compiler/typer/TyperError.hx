package sillyscript.compiler.typer;

import sillyscript.compiler.typer.SillyType;
import sillyscript.compiler.typer.ast.TypedCustomSyntaxDeclaration;
import sillyscript.compiler.typer.ast.TypedDef;

/**
	All the possible errors that can occur during typing.
**/
enum TyperError {
	/**
		An error that should be impossible to trigger.
		If encountered, it should be reported!
	**/
	CompilerError(message: String);

	NothingWithName(name: String);
	MissingArgument(def: TypedDef, argumentIndex: Int);
	WrongType(receivingType: SillyType, providingType: SillyType);
	WrongReturnType(receivingType: SillyType, providingType: SillyType);
	WrongRole;
	CannotPassNullableTypeToNonNullable;
	InconsistentTypeBetweenSyntaxTemplates;
	CannotCall(type: Null<SillyType>);
	AmbiguousCustomSyntaxCandidates(names: Array<String>);
	InvalidTypesForCustomSyntax(customSyntax: Null<TypedCustomSyntaxDeclaration>);
	InvalidTypesForMultipleCustomSyntaxCandidates(customSyntax: Array<TypedCustomSyntaxDeclaration>);
}
