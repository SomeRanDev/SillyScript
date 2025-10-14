package sillyscript.compiler.typer.subtyper;

import sillyscript.compiler.typer.ast.Scope;
import sillyscript.compiler.typer.ast.TypedDef;
import sillyscript.compiler.parser.UntypedAst.UntypedDefDeclaration;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.Positioned;

/**
	Handles the typing of `def` declarations.
**/
@:access(sillyscript.compiler.parser.Parser)
class DefDeclTyper {
	public static function type(
		typer: Typer,
		untypedDef: Positioned<UntypedDefDeclaration>
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
