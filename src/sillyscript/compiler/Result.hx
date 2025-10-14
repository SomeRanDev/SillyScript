package sillyscript.compiler;

import sillyscript.Positioned;

enum Result<ValueType, ErrorType> {
	Success(data: ValueType);
	Error(errors: Array<ErrorType>);
}

enum PositionedResult<ValueType, ErrorType> {
	Success(data: ValueType);
	Error(errors: Array<Positioned<ErrorType>>);
}
