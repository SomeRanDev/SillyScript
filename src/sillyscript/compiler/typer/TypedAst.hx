package sillyscript.compiler.typer;

import sillyscript.compiler.typer.ast.TypedEnum;
import sillyscript.compiler.typer.ast.Scope;
import sillyscript.compiler.typer.ast.TypedCustomSyntaxDeclaration;
import sillyscript.compiler.typer.ast.TypedDef;
import sillyscript.compiler.Value;
import sillyscript.Positioned;

/**
	A pairing of a name and a typed AST expression.
**/
typedef TypedDictionaryEntry = { key: Positioned<String>, value: Positioned<TypedAst> };

/**
	The AST of the SillyScript contents post-typing.
**/
enum TypedAst {
	Value(value: Value);
	List(items: Array<Positioned<TypedAst>>, scope: Scope);
	Dictionary(items: Array<Positioned<TypedDictionaryEntry>>, scope: Scope);
	DefIdentifier(typedDef: Positioned<TypedDef>);
	DefArgumentIdentifier(typedDef: Positioned<TypedDef>, argumentIndex: Int);
	EnumCaseIdentifier(enumDecl: Positioned<TypedEnum>, caseIndex: Int);
	Call(calledAst: Positioned<TypedAst>, arguments: Array<Positioned<TypedAst>>);
	CustomSyntax(customSyntax: TypedCustomSyntaxDeclaration, patternIndex: Int, expressions: Array<TypedDictionaryEntry>);
}
