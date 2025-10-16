package sillyscript.compiler.typer.subtyper;

import sillyscript.compiler.Result.PositionedResult;
import sillyscript.compiler.parser.AmbiguousType;
using sillyscript.extensions.ArrayExt;

class TypeTyper {
	public static function typeType(typer: Typer, ambiguousType: Positioned<AmbiguousType>): PositionedResult<SillyType, TyperError> {
		return switch(ambiguousType.value) {
			case Known(type): Success(type);
			case Unknown(name, type): {
				final kind = typer.findType(name.value);
				if(kind != null) {
					Success(type.withKind(kind));
				} else {
					Error([{
						value: UnknownType,
						position: ambiguousType.position
					}]);
				}
			}
			case WithUnknownSubtype(type, subtype): {
				final errors = [];
				final typedType = switch(typeType(typer, type)) {
					case Success(type): type;
					case Error(typingErrors): {
						errors.pushArray(typingErrors);
						SillyType.ANY;
					}
				}
				final typedSubtype = switch(typeType(typer, subtype)) {
					case Success(type): type;
					case Error(typingErrors): {
						errors.pushArray(typingErrors);
						SillyType.ANY;
					}
				}

				if(errors.length != 0) {
					Error(errors);
				} else {
					final finalType = typedType.withSubtype(typedSubtype);
					if(finalType != null) {
						Success(finalType);
					} else {
						Error([{
							value: CannotHaveSubtype,
							position: type.position
						}]);
					}
				}
			}
		}
	}
}