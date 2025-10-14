package sillyscript.compiler.typer.subtyper;

import sillyscript.compiler.parser.UntypedAst;
import sillyscript.compiler.typer.Typer;

class CallTyper {
	public static function type(
		typer: Typer,
		ast: Positioned<UntypedAst>,
		calledAst: Positioned<UntypedAst>,
		arguments: Array<{ name: Null<String>, value: Positioned<UntypedAst> }>
	): TyperResult {
		final errors = [];

		final positionedTypedAst = switch(typer.typeAst(calledAst)) {
			case Success(called): called;
			case Error(itemErrors): {
				for(e in itemErrors) errors.push(e);
				null;
			}
		}

		final typedNamedArguments = [];
		final typedUnnamedArguments = [];
		for(argument in arguments) {
			switch(typer.typeAst(argument.value)) {
				case Success(called): {
					if(argument.name == null) {
						typedUnnamedArguments.push(called);
					} else {
						typedNamedArguments.push({
							name: argument.name,
							value: called
						});
					}
				}
				case Error(itemErrors): {
					for(e in itemErrors) errors.push(e);
					null;
				}
			}
		}

		var orderedTypedArguments: Null<Array<Positioned<TypedAst>>> = null;

		switch(positionedTypedAst?.value) {
			case DefIdentifier(def): {
				final argumentSlots = [for(_ in 0...def.value.arguments.length) null];

				for(argument in typedNamedArguments) {
					if(argument.name != null) {
						for(i in 0...def.value.arguments.length) {
							if(argument.name == def.value.arguments[i].value.name.value) {
								argumentSlots[i] = argument.value;
							}
						}
					}
				}

				for(argument in typedUnnamedArguments) {
					for(i in 0...argumentSlots.length) {
						if(argumentSlots[i] == null) {
							argumentSlots[i] = argument;
							break;
						}
					}
				}

				orderedTypedArguments = [];
				var missingArgument = -1;
				for(i in 0...argumentSlots.length) {
					final a = argumentSlots[i];
					if(a == null) {
						missingArgument = i;
						break;
					} else {
						orderedTypedArguments.push(a);
					}
				}

				if(missingArgument >= 0) {
					errors.push({
						value: MissingArgument(def.value, missingArgument),
						position: ast.position
					});
				}
			}
			case _: {
				final type = if(positionedTypedAst != null) {
					SillyType.fromTypedAst(positionedTypedAst).asNullable();
				} else {
					null;
				}
				errors.push({
					value: CannotCall(type),
					position: ast.position
				});
			}
		}

		return if(
			positionedTypedAst != null && orderedTypedArguments != null && errors.length == 0
		) {
			Success({
				value: Call(positionedTypedAst, orderedTypedArguments),
				position: ast.position
			});
		} else {
			Error(errors);
		}
	}
}