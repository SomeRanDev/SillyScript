package sillyscript.compiler.typer.ast;

import sillyscript.compiler.typer.TypedAst;
import sillyscript.Positioned;

typedef TypedDefArgument = {
	name: Positioned<String>,
	type: Positioned<SillyType>,
	defaultValue: Null<Positioned<TypedAst>>
};

class TypedDef {
	static var maxId: Int = 0;

	public var name(default, null): String;
	public var arguments(default, null): Array<Positioned<TypedDefArgument>>;
	public var returnType(default, null): Positioned<SillyType>;
	public var content(default, null): Null<Positioned<TypedAst>>;
	public var id(default, null): Int;

	public function new(
		name: String,
		arguments: Array<Positioned<TypedDefArgument>>,
		returnType: Positioned<SillyType>
	) {
		this.name = name;
		this.arguments = arguments;
		this.returnType = returnType;
		this.content = null;
		this.id = maxId++;
	}

	public function setContent(content: Positioned<TypedAst>) {
		this.content = content;
	}

	public function toString() {
		var contentString = "";
		if(content != null) {
			contentString = Std.string(content.value);
		}
		return '{ name: $name, arguments: $arguments, returnType: $returnType, content: $contentString }';
	}
}
