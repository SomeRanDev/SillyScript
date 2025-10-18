package sillyscript.compiler.typer.ast;

import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration.CustomSyntaxPatternId;
import sillyscript.compiler.typer.subtyper.CustomSyntaxDeclTyper.TypedExpressionInputKind;
import sillyscript.compiler.typer.ast.Scope;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration.CustomSyntaxId;

@:structInit
class TypedCustomSyntaxDeclarationPattern {
	public var type(default, null): Positioned<SillyType>;
	public var id(default, null): CustomSyntaxPatternId;
}

class TypedCustomSyntaxDeclaration {
	public var name(default, null): Positioned<String>;
	public var id(default, null): CustomSyntaxId;
	public var scope(default, null): Scope;
	public var inputs(default, null): Array<{ name: String, type: TypedExpressionInputKind }>;
	public var patterns(default, null): Array<TypedCustomSyntaxDeclarationPattern>;

	public function new(
		name: Positioned<String>,
		id: CustomSyntaxId,
		scope: Scope,
		inputs: Array<{ name: String, type: TypedExpressionInputKind }>,
		patterns: Array<TypedCustomSyntaxDeclarationPattern>
	) {
		this.name = name;
		this.id = id;
		this.scope = scope;
		this.inputs = inputs;
		this.patterns = patterns;
	}

	public function inputsAsMap(): Map<String, TypedExpressionInputKind> {
		final result: Map<String, TypedExpressionInputKind> = [];
		for(i in inputs) {
			result.set(i.name, i.type);
		}
		return result;
	}
}
