package sillyscript.compiler.typer.subtyper;

import sillyscript.compiler.parser.UntypedAst.UntypedEnumDeclaration;
import haxe.ds.ReadOnlyArray;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration;
import sillyscript.compiler.parser.UntypedAst.UntypedDeclaration;
import sillyscript.compiler.parser.UntypedAst.UntypedDefDeclaration;
import sillyscript.compiler.typer.ast.Scope;
import sillyscript.Positioned;
using sillyscript.extensions.ArrayExt;

class DeclarationTyper {
	public static function type(
		typer: Typer,
		declarations: ReadOnlyArray<Positioned<UntypedDeclaration>>,
		errors: Array<Positioned<TyperError>>
	): Scope {
		final scope = new Scope();

		typer.pushScope(scope);

		// Type types first so they're accessible by `def`s.
		for(declaration in declarations) {
			switch(declaration.value) {
				case Enum(untypedEnum): {
					final positionedUntypedDef: Positioned<UntypedEnumDeclaration> = {
						value: untypedEnum,
						position: declaration.position
					};
					switch(EnumDeclTyper.type(typer, positionedUntypedDef)) {
						case Success(typedEnum): scope.addEnum(typedEnum);
						case Error(typedEnumErrors): errors.pushArray(typedEnumErrors);
					}
				}
				case _: {}
			}
		}

		// Type 
		for(declaration in declarations) {
			switch(declaration.value) {
				case Def(untypedDef): {
					final positionedUntypedDef: Positioned<UntypedDefDeclaration> = {
						value: untypedDef,
						position: declaration.position
					};
					switch(DefDeclTyper.type(typer, positionedUntypedDef)) {
						case Success(typedDef): scope.addDef(typedDef);
						case Error(typedDefErrors): errors.pushArray(typedDefErrors);
					}
				}
				case CustomSyntax(customSyntax): {
					final positionedUntypedCustomSyntax: Positioned<UntypedCustomSyntaxDeclaration> = {
						value: customSyntax,
						position: declaration.position
					};
					switch(CustomSyntaxDeclTyper.type(typer, positionedUntypedCustomSyntax)) {
						case Success(typedCustomSyntax): scope.addCustomSyntax(typedCustomSyntax);
						case Error(typedDefErrors): errors.pushArray(typedDefErrors);
					}
				}
				case _: {}
			}
		}

		return scope;
	}
}
