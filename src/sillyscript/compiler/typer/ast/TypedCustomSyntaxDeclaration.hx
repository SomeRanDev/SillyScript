package sillyscript.compiler.typer.ast;

import sillyscript.compiler.typer.ast.Scope;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration.CustomSyntaxId;

class TypedCustomSyntaxDeclaration {
	public var name(default, null): Positioned<String>;
	public var scope(default, null): Scope;
	public var id(default, null): CustomSyntaxId;
	public var inputs(default, null): Array<{ name: String, type: SillyType }>;

	public function new(
		name: Positioned<String>,
		scope: Scope,
		id: CustomSyntaxId,
		inputs: Array<{ name: String, type: SillyType }>
	) {
		this.name = name;
		this.scope = scope;
		this.id = id;
		this.inputs = inputs;
	}

	public function inputsAsMap(): Map<String, SillyType> {
		final result: Map<String, SillyType> = [];
		for(i in inputs) {
			result.set(i.name, i.type);
		}
		return result;
	}
}
