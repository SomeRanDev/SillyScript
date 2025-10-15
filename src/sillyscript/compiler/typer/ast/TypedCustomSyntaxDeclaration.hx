package sillyscript.compiler.typer.ast;

import sillyscript.compiler.typer.ast.Scope;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration.CustomSyntaxId;

class TypedCustomSyntaxDeclaration {
	public var name(default, null): Positioned<String>;
	public var id(default, null): CustomSyntaxId;
	public var scope(default, null): Scope;
	public var inputs(default, null): Array<{ name: String, type: SillyType }>;
	public var patternTypes(default, null): Array<Positioned<SillyType>>;

	public function new(
		name: Positioned<String>,
		id: CustomSyntaxId,
		scope: Scope,
		inputs: Array<{ name: String, type: SillyType }>,
		patternTypes: Array<Positioned<SillyType>>
	) {
		this.name = name;
		this.id = id;
		this.scope = scope;
		this.inputs = inputs;
		this.patternTypes = patternTypes;
	}

	public function inputsAsMap(): Map<String, SillyType> {
		final result: Map<String, SillyType> = [];
		for(i in inputs) {
			result.set(i.name, i.type);
		}
		return result;
	}
}
