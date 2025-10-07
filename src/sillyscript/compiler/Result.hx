package sillyscript.compiler;

import sillyscript.Positioned;

enum PositionedResult<ValueType, ErrorType> {
	Success(data: ValueType);
	Error(errors: Array<Positioned<ErrorType>>);
}
