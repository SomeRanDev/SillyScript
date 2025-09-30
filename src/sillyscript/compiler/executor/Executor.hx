package sillyscript.compiler.executor;

import sillyscript.compiler.executor.ExecutorError;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.compiler.typer.TypedAst;
import sillyscript.Position.Positioned;

typedef ExecutorResult = PositionedResult<Positioned<DataOutput>, ExecutorError>;

class Executor {
	var typedAst: Positioned<TypedAst>;
	var context: Context;

	public function new(typedAst: Positioned<TypedAst>, context: Context) {
		this.typedAst = typedAst;
		this.context = context;
	}

	public function execute(): ExecutorResult {
		return convertTypedAstToData(typedAst);
	}

	function convertTypedAstToData(ast: Positioned<TypedAst>): ExecutorResult {
		return switch(ast.value) {
			case Value(value): {
				Success({ value: Value(value), position: ast.position });
			}
			case List(items): {
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
			case Dictionary(items): {
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
			case Placeholder: {
				Error([{ value: Placeholder, position: ast.position }]);
			}
		}
	}
}