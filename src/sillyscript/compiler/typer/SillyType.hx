package sillyscript.compiler.typer;

import sillyscript.extensions.Nothing;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.compiler.typer.SillyTypeKind;
import sillyscript.compiler.typer.TyperError;
using sillyscript.extensions.ArrayExt;

/**
	Used internally as flags for `SillyType.findMatchingAttributes`.
**/
enum abstract SillyTypeMatchingAttributeFlags(Int) to Int {
	var Kind = 1;
	var Nullable = 2;
	var Role = 4;
	var All = 7;
}

/**
	Represents an entire SillyScript type.
**/
@:structInit
class SillyType {
	public static final ANY: SillyType = { kind: Any, nullable: false, role: null };

	public var kind(default, null): SillyTypeKind;
	public var nullable(default, null): Bool;
	public var role(default, null): Null<String>;

	/**
		Prints the type as it would be in valid SillyScript.
	**/
	public function toString(): String {
		return kind.toString() + (role != null ? "!" + role : "") + (nullable ? "?" : "");
	}

	/**
		Returns a copy of this `SillyType` with the subtype of `type`.

		Returns `null` if this type cannot contain a subtype.
	**/
	public function withSubtype(type: SillyType): Null<SillyType> {
		final newKind = switch(kind) {
			case List(_): List(type);
			case Dictionary(_): Dictionary(type);
			case _: return null;
		}

		return {
			kind: newKind,
			nullable: nullable,
			role: role
		};
	}

	/**
		Returns a copy of this `SillyType` as nullable.

		If the type is already nullable, returns itself without making a copy.
	**/
	public function asNullable(): SillyType {
		if(nullable) {
			return this;
		}

		return {
			kind: kind,
			nullable: true,
			role: role
		};
	}

	/**
		Returns `SillyTypeMatchingAttributeFlags` corresponding to the fields this instance matches
		with `other`.
	**/
	function findMatchingAttributes(other: SillyType): Int {
		var result = 0;
		if(kind.isEqual(other.kind)) {
			result |= Kind;
		}
		if(nullable == other.nullable) {
			result |= Nullable;
		}
		if(role == other.role) {
			result |= Role;
		}
		return result;
	}

	/**
		Checks if the two `SillyType` values are identical.
	**/
	public function isEqual(other: SillyType) {
		return findMatchingAttributes(other) == All;
	}

	/**
		Checks if the `other` `SillyType` can be provided to `self` `SillyType`.

		For instance, `int` can be passed to `int?` BUT `dict` cannot be passed to `dict!cool`.
	**/
	public function canReceiveType(other: SillyType): Result<Nothing, TyperError> {
		var attributes = findMatchingAttributes(other);

		// Instead of checking if kinds are equal, let's check if they can be "received".
		switch(kind.canReceiveType(other.kind)) {
			case Success(true): attributes |= Kind;
			case Success(false): {}
			case Error(e): return Error(e.map(function(e) {
				return switch(e) {
					case WrongType(_, _): WrongType(this, other);
					case e: e;
				}
			}));
		}

		// If the provided type has no role, allow it to be received regardless.
		if(role != null && other.role == null) {
			attributes |= Role;
		}

		if(attributes == All) {
			return Success(Nothing);
		}

		// If the only distinction is nullability, handle here...
		if(attributes == Kind | Role) {
			return if(nullable && !other.nullable) {
				Success(Nothing);
			} else {
				Error([CannotPassNullableTypeToNonNullable]);
			}
		}

		// Allow passing `null` to nullable.
		switch(other.kind) {
			case Null if(nullable): return Success(Nothing);
			case _:
		}

		// If `kind`s are the same, the only difference is `role`.
		if(attributes & Kind != 0) {
			return Error([WrongRole]);
		}

		return Error([WrongType(this, other)]);
	}

	/**
		Types `typedAst` and returns the type.
	**/
	public static function fromTypedAst(
		typedAst: Positioned<TypedAst>
	): PositionedResult<SillyType, TyperError> {
		return Success(switch(typedAst.value) {
			case Value(Null): {
				{ kind: Null, nullable: true, role: null }
			}
			case Value(Bool(_)): {
				{ kind: Bool, nullable: false, role: null }
			}
			case Value(Int(_)): {
				{ kind: Int, nullable: false, role: null }
			}
			case Value(Float(_)): {
				{ kind: Float, nullable: false, role: null }
			}
			case Value(String(_)): {
				{ kind: String, nullable: false, role: null }
			}
			case List(items, scope): {
				var innerType: Null<SillyType> = null;
				var isAny = false;
				for(item in items) {
					final itemType = switch(fromTypedAst(item)) {
						case Success(type): type;
						case Error(e): return Error(e);
					}
					if(innerType == null) {
						innerType = itemType;
					} else {
						if(!innerType.isEqual(itemType)) {
							isAny = true;
							break;
						}
					}
				}

				final innerType: SillyType = if(isAny || innerType == null) {
					ANY;
				} else {
					innerType;
				}

				{
					kind: List(innerType),
					nullable: false,
					role: null
				}
			}
			case Dictionary(items, _): {
				var innerType: Null<SillyType> = null;
				var isAny = false;
				for(item in items) {
					final itemType = switch(fromTypedAst(item.value.value)) {
						case Success(type): type;
						case Error(e): return Error(e);
					}
					if(innerType == null) {
						innerType = itemType;
					} else {
						if(!innerType.isEqual(itemType)) {
							isAny = true;
							break;
						}
					}
				}

				final innerType: SillyType = if(isAny || innerType == null) {
					ANY;
				} else {
					innerType;
				}

				{
					kind: Dictionary(innerType),
					nullable: false,
					role: null
				}
			}
			case DefIdentifier(typedDef): {
				final t: SillyType = {
					kind: Callable(Def(typedDef.value)),
					nullable: false,
					role: null
				};
				t;
			}
			case DefArgumentIdentifier(typedDef, argumentIndex): {
				typedDef.value.arguments[argumentIndex].value.type.value;
			}
			case Call(calledAst, _): {
				final type = switch(fromTypedAst(calledAst)) {
					case Success(type): type;
					case Error(e): return Error(e);
				}
				switch(type.kind) {
					case Callable(Def(typedDef)): {
						typedDef.returnType.value;
					}
					case _: {
						final te: Positioned<TyperError> = {
							value: CannotCall(type),
							position: typedAst.position
						};
						return Error([te]);
					}
				}
			}
			case CustomSyntax(customSyntax, patternIndex, _): {
				customSyntax.patternTypes.get(patternIndex)?.value ?? ({
					kind: Dictionary(ANY),
					nullable: false,
					role: null
				} : SillyType);
			}
		});
	}
}
