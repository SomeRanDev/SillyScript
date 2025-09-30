package sillyscript.compiler;

import sillyscript.compiler.Parser.Ast;
import sillyscript.Position.Positioned;
import sillyscript.compiler.Parser.Value;

/**
	Typed syntax tree.
**/
enum TypedAst {
	Value(value: Value);
	List(items: Array<Positioned<TypedAst>>);
	Dictionary(items: Array<Positioned<{ key: Positioned<String>, value: Positioned<TypedAst> }>>);
	Placeholder;
}

enum TyperError {
	Placeholder;
}

enum TyperResult {
	Success(typedAst: Positioned<TypedAst>);
	Error(errors: Array<Positioned<TyperError>>);
}

class Typer {
	var untypedAst: Positioned<Ast>;
	var context: Context;
	var errors: Array<Positioned<TyperError>>;

	/**
		Constructor.
	**/
	public function new(untypedAst: Positioned<Ast>, context: Context) {
		this.untypedAst = untypedAst;
		this.context = context;

		errors = [];
	}

	public function type(): TyperResult {
		return typeAst(untypedAst);
	}

	function typeAst(ast: Positioned<Ast>): TyperResult {
		return switch(ast.value) {
			case Value(value): {
				Success({ value: Value(value), position: ast.position });
			}
			case List(items): {
				final typedEntries = [];
				final errors = [];
				for(item in items) {
					switch(typeAst(item)) {
						case Success(typedAst): typedEntries.push(typedAst);
						case Error(itemErrors): for(e in itemErrors) errors.push(e);
					}
				}
				if(errors.length > 0) {
					Error(errors);
				} else {
					Success({ value: List(typedEntries), position: ast.position });
				}
			}
			case Dictionary(items): {
				final typedEntries: Array<Positioned<{ key: Positioned<String>, value: Positioned<TypedAst> }>> = [];
				final errors = [];
				for(item in items) {
					switch(typeAst(item.value.value)) {
						case Success(typedAst): typedEntries.push({
							value: { key: item.value.key, value: typedAst },
							position: item.position
						});
						case Error(itemErrors): for(e in itemErrors) errors.push(e);
					}
				}
				if(errors.length > 0) {
					Error(errors);
				} else {
					Success({ value: Dictionary(typedEntries), position: ast.position });
				}
			}
			case Call(identifier, arguments): {
				Success({ value: Placeholder, position: ast.position });
			}
		}
	}
}