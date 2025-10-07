package sillyscript.compiler.typer.subtyper;

import sillyscript.compiler.Result.PositionedResult;
import sillyscript.compiler.parser.ParserError;
import sillyscript.compiler.parser.subparsers.DefParser.UntypedDef;
import sillyscript.Positioned;

@:structInit
class TypedDef {
	static var maxId: Int = 0;

	public var name(default, null): String;
	public var arguments(default, null): Array<Positioned<{ name: Positioned<String>, type: Positioned<Type> }>>;
	public var returnType(default, null): Positioned<Type>;
	public var content(default, null): Null<Positioned<TypedAst>>;
	public var id(default, null): Int;

	public function new(
		name: String,
		arguments: Array<Positioned<{ name: Positioned<String>, type: Positioned<Type> }>>,
		returnType: Positioned<Type>
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

/**
	Handles the typing of `def` declarations.
**/
@:access(sillyscript.compiler.parser.Parser)
class DefTyper {
	public static function type(
		typer: Typer,
		untypedDef: Positioned<UntypedDef>
	): PositionedResult<Positioned<TypedDef>, TyperError> {
		final typedDef = new TypedDef(
			untypedDef.value.name,
			untypedDef.value.arguments,
			untypedDef.value.returnType
		);

		final scope = new Scope();
		scope.addContainedInDefs({ value: typedDef, position: untypedDef.position });
		typer.pushScope(scope);
		final typingResult = typer.typeAst(untypedDef.value.content);
		typer.popScope();

		return switch(typingResult) {
			case Success(data): {
				typedDef.setContent(data);
				Success({
					value: typedDef,
					position: untypedDef.position
				});
			}
			case Error(errors): {
				Error(errors);
			}
		}
	}
}
