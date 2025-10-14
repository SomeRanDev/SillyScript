package sillyscript.compiler;

import sillyscript.Positioned;

enum Result<ValueType, ErrorType> {
	Success(data: ValueType);
	Error(errors: Array<ErrorType>);
}

@:using(sillyscript.compiler.Result.PositionedResultExt)
enum PositionedResult<ValueType, ErrorType> {
	Success(data: ValueType);
	Error(errors: Array<Positioned<ErrorType>>);
}

class PositionedResultExt {
	public static inline function asNullable<ValueType, ErrorType>(
		self: PositionedResult<ValueType, ErrorType>
	): Null<ValueType> {
		return switch(self) {
			case Success(value): value;
			case _: null;
		}
	}
}
