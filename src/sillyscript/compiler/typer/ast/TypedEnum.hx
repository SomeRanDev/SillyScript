package sillyscript.compiler.typer.ast;

class TypedEnum {
	static var maxId: Int = 0;

	public var name(default, null): Positioned<String>;
	public var type(default, null): Positioned<SillyType>;
	public var cases(default, null): Array<Positioned<String>>;
	public var id(default, null): Int;

	public function new(
		name: Positioned<String>,
		type: Positioned<SillyType>,
		cases: Array<Positioned<String>>
	) {
		this.name = name;
		this.type = type;
		this.cases = cases;
		this.id = maxId++;
	}

	public function toString() {
		return 'TypedEnum(id: $id, name: $name, type: $type, cases: $cases)';
	}
}
