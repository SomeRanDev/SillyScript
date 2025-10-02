package sillyscript.compiler.typer;

enum TypeKind {
	Any;
	Bool;
	Int;
	Float;
	String;
	List(subtype: Type);
	Dictionary(subtype: Type);
}

@:structInit
class Type {
	public static final PLACEHOLDER: Type = { kind: Any, nullable: false, role: null };

	public var kind(default, null): TypeKind;
	public var nullable(default, null): Bool;
	public var role(default, null): Null<String>;

	public function withSubtype(type: Type): Null<Type> {
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
}
