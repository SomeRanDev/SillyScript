package sillyscript.compiler.typer.subtyper;

import sillyscript.compiler.parser.subparsers.DefParser.UntypedDef;
import sillyscript.compiler.parser.UntypedAst.UntypedDeclaration;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.compiler.typer.subtyper.DefTyper.TypedDef;
import sillyscript.Positioned;

class DeclarationTyper {
	public static function type(
		typer: Typer,
		declarations: Array<Positioned<UntypedDeclaration>>,
		errors: Array<Positioned<TyperError>>
	): Scope {
		final scope = new Scope();

		for(declaration in declarations) {
			switch(declaration.value) {
				case Def(untypedDef): {
					final positionedUntypedDef: Positioned<UntypedDef> = {
						value: untypedDef,
						position: declaration.position
					};
					switch(DefTyper.type(typer, positionedUntypedDef)) {
						case Success(typedDef): {
							scope.addDef(typedDef);
						}
						case Error(typedDefErrors): {
							for(e in typedDefErrors) {
								errors.push(e);
							}
						}
					}
				}
			}
		}

		return scope;
	}
}
