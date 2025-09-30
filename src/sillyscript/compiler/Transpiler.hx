package sillyscript.compiler;

import sillyscript.compiler.Executor.DataOutput;
import sillyscript.Position.Positioned;

enum TranspilerError {
	Placeholder;
}

enum TranspilerResult {
	Success(content: String);
	Error(errors: Array<Positioned<TranspilerError>>);
}

abstract class Transpiler {
	var data: Positioned<DataOutput>;
	var context: Context;

	public function new(data: Positioned<DataOutput>, context: Context) {
		this.data = data;
		this.context = context;
	}

	public abstract function transpile(): TranspilerResult;
}