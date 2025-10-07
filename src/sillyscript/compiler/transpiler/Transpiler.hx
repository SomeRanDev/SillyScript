package sillyscript.compiler.transpiler;

import sillyscript.compiler.executor.DataOutput;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.Positioned;

typedef TranspilerResult = PositionedResult<String, TranspilerError>;

abstract class Transpiler {
	var data: Positioned<DataOutput>;
	var context: Context;

	public function new(data: Positioned<DataOutput>, context: Context) {
		this.data = data;
		this.context = context;
	}

	public abstract function transpile(): TranspilerResult;
}