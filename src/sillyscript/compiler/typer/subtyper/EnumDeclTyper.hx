package sillyscript.compiler.typer.subtyper;

import sillyscript.compiler.typer.ast.TypedEnum;
import sillyscript.compiler.parser.UntypedAst.UntypedEnumDeclaration;
import sillyscript.compiler.parser.UntypedAst.UntypedDefDeclaration;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.compiler.typer.ast.Scope;
import sillyscript.compiler.typer.ast.TypedDef;
import sillyscript.compiler.typer.TyperError;
import sillyscript.extensions.Nothing;
import sillyscript.Positioned;

/**
	Handles the typing of `enum` declarations.
**/
@:access(sillyscript.compiler.parser.Parser)
class EnumDeclTyper {
	/**
		Types an untyped `enum` declaration.
	**/
	public static function type(
		typer: Typer,
		untypedEnum: Positioned<UntypedEnumDeclaration>
	): PositionedResult<Positioned<TypedEnum>, TyperError> {
		final type: Positioned<SillyType> = {
			final maybeAmbiguousType = untypedEnum.value.type;
			if(maybeAmbiguousType != null) {
				switch(TypeTyper.typeType(typer, maybeAmbiguousType)) {
					case Success(type): { value: type, position: maybeAmbiguousType.position };
					case Error(e): return Error(e);
				}
			} else {
				{ value: SillyType.INT, position: Position.INVALID };
			}
		};

		return Success({
			value: new TypedEnum(
				untypedEnum.value.name,
				type,
				untypedEnum.value.cases
			),
			position: untypedEnum.position
		});
	}
}
