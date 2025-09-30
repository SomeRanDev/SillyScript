package sillyscript.compiler.parser;

import sillyscript.compiler.parser.ParserError;
import sillyscript.Position.Positioned;

/**
	Used to distinguish the result from a parsing function.
**/
@:using(sillyscript.compiler.parser.ParserResult.ParseResultExt)
enum ParseResult<T> {
	/**
		The value was successfully parsed and scanner advanced.
	**/
	Success(result: T);

	/**
		The syntax does not match what was requested to be parsed.

		This check was done safely and the `currentIndex` is unchanged.
	**/
	NoMatch;

	/**
		There was a partial match of the requested syntax, but it is not completely valid and 
		will result in an error.

		The `currentIndex` was advanced by the offset defined by `offset`.
	**/
	Error(errors: Array<Positioned<ParserError>>);
}

/**
	The functions for the `ParseResult`.
**/
class ParseResultExt {
	/**
		Maps the contents of one `ParseResult` into another.

		`extraOffset` is added to the `offset` of `ErrorMatch` if it's returned.
		`returnErrorForNoMatch` returns `ErrorMatch` if `self` is `NoMatch`.
		`callback` converts the value from `T` to `U`. If is ONLY called if `self` is `Success`.
	**/
	public static function map<T, U>(
		self: ParseResult<T>,
		returnErrorForNoMatch: Null<Positioned<ParserError>>,
		callback: (T) -> U
	): ParseResult<U> {
		return switch(self) {
			case Success(result): Success(callback(result));
			case NoMatch: if(returnErrorForNoMatch != null) {
				Error([returnErrorForNoMatch]);
			} else {
				NoMatch;
			}
			case Error(error): Error(error);
		}
	}
}
