package sillyscript.compiler.typer;

import sillyscript.compiler.typer.SillyType;
import sillyscript.compiler.typer.ast.TypedEnum;
import sillyscript.extensions.Nothing;
import sillyscript.compiler.typer.ast.TypedDef;

/**
	The kind of type for a SillyScript type.
**/
@:using(sillyscript.compiler.typer.SillyTypeKind.SillyTypeKindExt)
enum SillyTypeKind {
	Any;
	Null;
	Bool;
	Int;
	Float;
	String;
	List(subtype: SillyType);
	Dictionary(subtype: SillyType);
	Callable(callable: CallableAst);
	Enum(typedEnum: Positioned<TypedEnum>);
	Or(possibilities: Array<SillyType>);
}

/**
	All possible callable AST structure cases.
**/
enum CallableAst {
	Def(typedDef: TypedDef);
}

/**
	Functions for `SillyTypeKind`.
**/
class SillyTypeKindExt {
	/**
		Prints the type kind as it would be in valid SillyScript.
	**/
	public static function toString(self: SillyTypeKind) {
		return switch(self) {
			case Any: "any";
			case Null: "null";
			case Bool: "bool";
			case Int: "int";
			case Float: "float";
			case String: "string";
			case List(subtype): subtype.toString() + " list";
			case Dictionary(subtype): subtype.toString() + " dict";
			case Callable(Def(typedDef)): typedDef.name + " callable";
			case Enum(typedEnum): "enum(" + typedEnum.value.name.value + ")";
			case Or(possibilities): possibilities.join(" | ");
		}
	}

	/**
		Checks if the two `SillyTypeKind` values are identical.
	**/
	public static function isEqual(self: SillyTypeKind, other: SillyTypeKind): Bool {
		return switch(self) {
			case Any: switch(other) { case Any: true; case _: false; }
			case Null: switch(other) { case Null: true; case _: false; }
			case Bool: switch(other) { case Bool: true; case _: false; }
			case Int: switch(other) { case Int: true; case _: false; }
			case Float: switch(other) { case Float: true; case _: false; }
			case String: switch(other) { case String: true; case _: false; }
			case List(subtype): switch(other) {
				case List(otherSubtype): subtype.isEqual(otherSubtype);
				case _: false;
			}
			case Dictionary(subtype): switch(other) {
				case Dictionary(otherSubtype): subtype.isEqual(otherSubtype);
				case _: false;
			}
			case Callable(Def(typedDef)): switch(other) {
				case Callable(Def(otherTypedDef)): typedDef.id == otherTypedDef.id;
				case _: false;
			}
			case Enum(typedEnum): switch(other) {
				case Enum(otherTypedEnum): typedEnum.value.id == otherTypedEnum.value.id;
				case _: false;
			}
			case Or(possibilities): switch(other) {
				case Or(otherPossibilities) if(possibilities.length == otherPossibilities.length): {
					var result = true;
					for(i in 0...possibilities.length) {
						if(!possibilities[i].isEqual(otherPossibilities[i])) {
							result = false;
							break;
						}
					}
					result;
				}
				case _: false;
			}
		}
	}

	/**
		Checks if the `other` `SillyTypeKind` can be provided to `self` `SillyTypeKind`.

		For instance, `int list` can be passed to `any list`.
	**/
	public static function canReceiveType(
		self: SillyTypeKind,
		other: SillyTypeKind
	): Result<Bool, TyperError> {
		return switch(self) {
			case Any: Success(true);
			case List(subtype): switch(other) {
				case List(otherSubtype): switch(subtype.canReceiveType(otherSubtype)) {
					case Success(Nothing): Success(true);
					case Error(e): Error(e);
				}
				case _: Success(false);
			}
			case Dictionary(subtype): switch(other) {
				case Dictionary(otherSubtype): switch(subtype.canReceiveType(otherSubtype)) {
					case Success(Nothing): Success(true);
					case Error(e): Error(e);
				}
				case _: Success(false);
			}
			case _: Success(isEqual(self, other));
		}
	}
}
