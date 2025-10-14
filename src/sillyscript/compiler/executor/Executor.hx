package sillyscript.compiler.executor;

import sillyscript.extensions.Stack;
import sillyscript.compiler.executor.ExecutorError;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.compiler.typer.TypedAst;
import sillyscript.Positioned;
using sillyscript.extensions.ArrayExt;

typedef ExecutorResult = PositionedResult<Positioned<DataOutput>, ExecutorError>;

class Executor {
	var typedAst: Positioned<TypedAst>;
	var context: Context;

	var argumentStack: Stack<{ id: Int, arguments: Array<Positioned<TypedAst>> }>;

	public function new(typedAst: Positioned<TypedAst>, context: Context) {
		this.typedAst = typedAst;
		this.context = context;

		argumentStack = [];
	}

	public function execute(): ExecutorResult {
		return convertTypedAstToData(typedAst);
	}

	function convertTypedAstToData(ast: Positioned<TypedAst>): ExecutorResult {
		return switch(ast.value) {
			case Value(value): {
				Success({ value: Value(value), position: ast.position });
			}
			case List(items, scope): {
				final typedEntries = [];
				final errors = [];
				for(item in items) {
					switch(convertTypedAstToData(item)) {
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
			case Dictionary(items, scope): {
				final typedEntries: Array<Positioned<{ key: Positioned<String>, value: Positioned<DataOutput> }>> = [];
				final errors = [];
				for(item in items) {
					switch(convertTypedAstToData(item.value.value)) {
						case Success(dataOutput): typedEntries.push({
							value: { key: item.value.key, value: dataOutput },
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
			case DefIdentifier(typedDef): {
				Error([{
					value: CannotExecuteDefIdentifier,
					position: ast.position
				}]);
			}
			case DefArgumentIdentifier(typedDef, argumentIndex): {
				var result: Null<ExecutorResult> = null;
				for(argumentCollection in argumentStack.bottomToTopIterator()) {
					if(typedDef.value.id == argumentCollection.id) {
						if(argumentIndex >= 0 && argumentIndex < argumentCollection.arguments.length) {
							final typedAst = argumentCollection.arguments.get(argumentIndex);
							if(typedAst != null) {
								result = convertTypedAstToData(typedAst);
							}
						}
					}
				}

				if(result != null) {
					result;
				} else {
					Error([{
						value: UnidentifiedDefArgumentIdentifier,
						position: ast.position
					}]);
				}
			}
			case Call(positionedTypedAst, arguments): {
				switch(positionedTypedAst.value) {
					case DefIdentifier(typedDef): {
						final content = typedDef.value.content;
						if(content != null) {
							argumentStack.pushTop({ id: typedDef.value.id, arguments: arguments });
							final data = convertTypedAstToData(content);
							argumentStack.popTop();
							data;
						} else {
							Error([{
								value: CannotExecuteEmptyDef,
								position: positionedTypedAst.position
							}]);
						}
					}
					case _: {
						Error([{
							value: CannotCallExpression,
							position: positionedTypedAst.position
						}]);
					}
				}
			}
			case CustomSyntax(customSyntax, expressions): {
				final typedEntries: Array<Positioned<{
					key: Positioned<String>,
					value: Positioned<DataOutput>
				}>> = [];
				final errors = [];
				for(expression in expressions) {
					switch(convertTypedAstToData(expression.value)) {
						case Success(typedAst): typedEntries.push({
							value: {
								key: expression.key,
								value: typedAst
							},
							position: expression.value.position
						});
						case Error(itemErrors): {
							for(e in itemErrors) {
								errors.push(e);
							}
						}
					}
				}
				if(errors.length > 0) {
					Error(errors);
				} else {
					Success({ value: Dictionary(typedEntries), position: ast.position });
				}
			}
		}
	}
}
