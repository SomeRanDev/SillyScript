package sillyscript.compiler.typer;

import sillyscript.compiler.parser.subparsers.DefParser.UntypedDef;
import sillyscript.compiler.typer.subtyper.DefTyper.TypedDef;
import sillyscript.Positioned;

enum TypedDeclaration {
	Def(def: Positioned<TypedDef>);
	DefArgument(def: Positioned<TypedDef>, index: Int);
}

class Scope {
	var defs: Array<Positioned<TypedDef>>;
	var containedInDefs: Array<Positioned<TypedDef>>;

	public function new() {
		defs = [];
		containedInDefs = [];
	}

	public function addDef(def: Positioned<TypedDef>) {
		defs.push(def);
	}

	public function addContainedInDefs(def: Positioned<TypedDef>) {
		containedInDefs.push(def);
	}

	public function findIdentifier(name: String): Null<TypedDeclaration> {
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
}

