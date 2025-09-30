package sillyscript.compiler;

import sillyscript.Position.Positioned;

enum PositionedResult<ValueType, ErrorType> {
	Success(data: ValueType);
	Error(errors: Array<Positioned<ErrorType>>);
}
