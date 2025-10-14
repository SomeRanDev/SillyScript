package sillyscript.compiler.typer.ast;

import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration.CustomSyntaxId;
import sillyscript.compiler.typer.ast.TypedCustomSyntaxDeclaration;
import sillyscript.compiler.typer.ast.TypedDef;
import sillyscript.Positioned;

/**
	A collection of declarations that are not expressions themselves and abide by scoping rules.
**/
class Scope {
	var defs: Array<Positioned<TypedDef>>;
	var customSyntaxes: Array<Positioned<TypedCustomSyntaxDeclaration>>;
	var containedInDefs: Array<Positioned<TypedDef>>;

	public function new() {
		defs = [];
		customSyntaxes = [];
		containedInDefs = [];
	}

	public function addDef(def: Positioned<TypedDef>) {
		defs.push(def);
	}

	public function addCustomSyntax(customSyntax: Positioned<TypedCustomSyntaxDeclaration>) {
		customSyntaxes.push(customSyntax);
	}

	public function addContainedInDefs(def: Positioned<TypedDef>) {
		containedInDefs.push(def);
	}

	public function findIdentifier(name: String): Null<TypedIdentifier> {
		for(def in defs) {
			if(def.value.name == name) {
				return Def(def);
			}
		}
		for(def in containedInDefs) {
			final arguments = def.value.arguments;
			for(i in 0...arguments.length) {
				if(arguments[i].value.name.value == name) {
					return DefArgument(def, i);
				}
			}
		}
		return null;
	}

	public function findCustomSyntax(id: CustomSyntaxId): Null<TypedCustomSyntaxDeclaration> {
		for(cs in customSyntaxes) {
			if(cs.value.id == id) {
				return cs.value;
			}
		}
		return null;
	}
}

