package sillyscript.compiler.parser;

import sillyscript.Positioned;
import sillyscript.compiler.typer.SillyType;

/**
	Represents a type that was parsed.

	Since we do not know all possible types during parsing, user-defined types like `enum`s are set
	to `Unknown` until the typing phase.
**/
@:using(sillyscript.compiler.parser.AmbiguousType.AmbiguousTypeExt)
enum AmbiguousType {
	Known(type: SillyType);
	Unknown(name: Positioned<String>, type: SillyType);
	WithUnknownSubtype(type: Positioned<AmbiguousType>, subtype: Positioned<AmbiguousType>);
}

/**
	Functions for `AmbiguousType`.
**/
class AmbiguousTypeExt {
	/**
		Returns a copy of `self` with a subtype of `subtype`.

		If `null` is returned, that means both `self` and `subtype` are known, but `self` cannot
		have a subtype.
	**/
	public static function withSubtype(self: AmbiguousType, position: Position, subtype: Positioned<AmbiguousType>): Null<AmbiguousType> {
		// If both types are known, simply use `SillyType.withSubtype`.
		switch(self) {
			case Known(knownType): switch(subtype.value) {
				case Known(knownSubtype): {
					final newType = knownType.withSubtype(knownSubtype);
					newType == null ? null : Known(newType);
				}
				case _:
			}
			case _:
		}

		return WithUnknownSubtype({ value: self, position: position }, subtype);
	}
}
