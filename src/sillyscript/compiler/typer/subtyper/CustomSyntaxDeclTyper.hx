package sillyscript.compiler.typer.subtyper;

import sillyscript.compiler.typer.ast.TypedCustomSyntaxDeclaration;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.Positioned;
using sillyscript.extensions.ArrayExt;

/**
	Handles the typing of custom syntax declarations.
**/
@:access(sillyscript.compiler.parser.Parser)
class CustomSyntaxDeclTyper {
	public static function type(
		typer: Typer,
		untypedCustomSyntax: Positioned<UntypedCustomSyntaxDeclaration>
	): PositionedResult<Positioned<TypedCustomSyntaxDeclaration>, TyperError> {
		final errors = [];
		final scope = DeclarationTyper.type(typer, untypedCustomSyntax.value.declarations, errors);

		if(errors.length > 0) {
			return Error(errors);
		}

		final errors: Array<Positioned<TyperError>> = [];

		final inputsMap: Map<String, { type: SillyType, count: Int }> = [];
		final patternTypes: Array<Positioned<SillyType>> = [];
		for(pattern in untypedCustomSyntax.value.patterns) {
			final type = switch(TypeTyper.typeType(typer, pattern.returnType)) {
				case Success(type): type;
				case Error(typeErrors): {
					errors.pushArray(typeErrors);
					continue;
				}
			}

			patternTypes.push({ value: type, position: pattern.returnType.position });

			for(token in pattern.tokenPattern) {
				switch(token) {
					case ExpressionInput(name, type): {
						final type = switch(TypeTyper.typeType(typer, type)) {
							case Success(type): type;
							case Error(typeErrors): {
								errors.pushArray(typeErrors);
								continue;
							}
						}

						if(inputsMap.exists(name.value)) {
							final o = inputsMap.get(name.value);
							if(o != null) {
								o.count++;

								if(!type.isEqual(o.type)) {
									errors.push({
										value: TyperError.InconsistentTypeBetweenSyntaxTemplates,
										position: name.position
									});
								}
							}
						} else {
							inputsMap.set(name.value, {
								type: type,
								count: 1
							});
						}
					}
					case Token(_):
				}
			}
		}

		if(errors.length > 0) {
			return Error(errors);
		}

		final inputs: Array<{ name: String, type: SillyType }> = [];
		for(name => data in inputsMap) {
			inputs.push({
				name: name,
				type: if(data.count < untypedCustomSyntax.value.patterns.length) {
					data.type.asNullable();
				} else {
					data.type;
				}
			});
		}

		return Success(
			untypedCustomSyntax.map(function(ucs) {
				return new TypedCustomSyntaxDeclaration(
					untypedCustomSyntax.value.name, ucs.id, scope, inputs, patternTypes
				);
			})
		);
	}
}
