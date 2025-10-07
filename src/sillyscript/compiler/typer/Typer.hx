package sillyscript.compiler.typer;

import sillyscript.compiler.typer.subtyper.DeclarationTyper;
import sillyscript.compiler.typer.subtyper.DefTyper;
import sillyscript.compiler.parser.UntypedAst;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.compiler.typer.TyperError;
import sillyscript.Positioned;

typedef TyperResult = PositionedResult<Positioned<TypedAst>, TyperError>;

class Typer {
	var untypedAst: Positioned<UntypedAst>;
	var context: Context;
	var errors: Array<Positioned<TyperError>>;
	var scopeStack: Array<Scope>;

	/**
		Constructor.
	**/
	public function new(untypedAst: Positioned<UntypedAst>, context: Context) {
		this.untypedAst = untypedAst;
		this.context = context;

		errors = [];
		scopeStack = [];
	}

	public function pushScope(scope: Scope) {
		scopeStack.push(scope);
	}

	public function popScope() {
		scopeStack.pop();
	}

	public function type(): TyperResult {
		return typeAst(untypedAst);
	}

	public function typeAst(ast: Positioned<UntypedAst>): TyperResult {
		return switch(ast.value) {
			case Identifier(name): {
				for(i in 0...scopeStack.length) {
					final scope = scopeStack[scopeStack.length - i - 1];
					switch(scope.findIdentifier(name)) {
						case Def(def): {
							return Success({
								value: DefIdentifier(def),
								position: ast.position
							});
						}
						case DefArgument(def, index): {
							return Success({
								value: DefArgumentIdentifier(def, index),
								position: ast.position
							});
						}
						case _:
					}
				}

				return Error([{
					value: NothingWithName(name),
					position: ast.position
				}]);
			}
			case Value(value): {
				Success({
					value: Value(value),
					position: ast.position
				});
			}
			case List(items, declarations): {
				final typedEntries = [];
				final errors = [];
				final scope = DeclarationTyper.type(this, declarations, errors);

				pushScope(scope);
				for(item in items) {
					switch(typeAst(item)) {
						case Success(typedAst): typedEntries.push(typedAst);
						case Error(itemErrors): for(e in itemErrors) errors.push(e);
					}
				}
				popScope();

				if(errors.length > 0) {
					Error(errors);
				} else {
					Success({
						value: List(typedEntries, scope),
						position: ast.position
					});
				}
			}
			case Dictionary(items, declarations): {
				final typedEntries: Array<Positioned<{ key: Positioned<String>, value: Positioned<TypedAst> }>> = [];
				final errors = [];
				final scope = DeclarationTyper.type(this, declarations, errors);

				pushScope(scope);
				for(item in items) {
					switch(typeAst(item.value.value)) {
						case Success(typedAst): typedEntries.push({
							value: { key: item.value.key, value: typedAst },
							position: item.position
						});
						case Error(itemErrors): for(e in itemErrors) errors.push(e);
					}
				}
				popScope();

				if(errors.length > 0) {
					Error(errors);
				} else {
					Success({
						value: Dictionary(typedEntries, scope),
						position: ast.position
					});
				}
			}
			case Call(called, arguments): {
				final errors = [];

				final positionedTypedAst = switch(typeAst(called)) {
					case Success(called): called;
					case Error(itemErrors): {
						for(e in itemErrors) errors.push(e);
						null;
					}
				}

				final typedNamedArguments = [];
				final typedUnnamedArguments = [];
				for(argument in arguments) {
					switch(typeAst(argument.value)) {
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
						errors.push({
							value: CannotCallExpression,
							position: ast.position
						});
					}
				}

				if(positionedTypedAst != null && orderedTypedArguments != null && errors.length == 0) {
					Success({
						value: Call(positionedTypedAst, orderedTypedArguments),
						position: ast.position
					});
				} else {
					Error(errors);
				}
			}
		}
	}
}