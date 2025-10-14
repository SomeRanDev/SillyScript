package sillyscript.compiler.typer.subtyper;

import haxe.ds.ReadOnlyArray;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration;
import sillyscript.compiler.parser.UntypedAst.UntypedDeclaration;
import sillyscript.compiler.parser.UntypedAst.UntypedDefDeclaration;
import sillyscript.compiler.typer.ast.Scope;
import sillyscript.Positioned;

class DeclarationTyper {
	public static function type(
		typer: Typer,
		declarations: ReadOnlyArray<Positioned<UntypedDeclaration>>,
		errors: Array<Positioned<TyperError>>
	): Scope {
		final scope = new Scope();

		for(declaration in declarations) {
			switch(declaration.value) {
				case Def(untypedDef): {
					final positionedUntypedDef: Positioned<UntypedDefDeclaration> = {
						value: untypedDef,
						position: declaration.position
					};
					switch(DefDeclTyper.type(typer, positionedUntypedDef)) {
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
				case CustomSyntax(customSyntax): {
					final positionedUntypedCustomSyntax: Positioned<UntypedCustomSyntaxDeclaration> = {
						value: customSyntax,
						position: declaration.position
					};
					switch(CustomSyntaxDeclTyper.type(typer, positionedUntypedCustomSyntax)) {
						case Success(typedCustomSyntax): {
							scope.addCustomSyntax(typedCustomSyntax);
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
