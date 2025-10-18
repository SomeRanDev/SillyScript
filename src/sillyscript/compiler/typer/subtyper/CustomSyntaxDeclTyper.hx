package sillyscript.compiler.typer.subtyper;

import sillyscript.compiler.typer.SillyType;
import sillyscript.compiler.typer.ast.TypedCustomSyntaxDeclaration;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.Positioned;
using sillyscript.extensions.ArrayExt;

/**
	Stores whether the input has a type or a possibly nullable custom syntax.
**/
@:using(sillyscript.compiler.typer.subtyper.CustomSyntaxDeclTyper.TypedExpressionInputKindExt)
enum TypedExpressionInputKind {
	TypedExpressionInput(type: SillyType);
	CustomSyntaxInput(id: CustomSyntaxId, nullable: Bool);
}

/**
	Functions for `TypedExpressionInputKind`.
**/
class TypedExpressionInputKindExt {
	public static function isEqual(self: TypedExpressionInputKind, other: TypedExpressionInputKind): Bool {
		return switch(self) {
			case TypedExpressionInput(type): switch(other) {
				case TypedExpressionInput(otherType): type.isEqual(otherType);
				case _: false;
			}
			case CustomSyntaxInput(id, nullable): switch(other) {
				case CustomSyntaxInput(otherId, otherNullable): id == otherId && nullable == otherNullable;
				case _: false;
			}
		}
	}

	public static function asNullable(self: TypedExpressionInputKind): TypedExpressionInputKind {
		return switch(self) {
			case TypedExpressionInput(type): TypedExpressionInput(type.asNullable());
			case CustomSyntaxInput(id, nullable): CustomSyntaxInput(id, true);
		}
	}
}

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

		final inputsMap: Map<String, { type: TypedExpressionInputKind, count: Int }> = [];
		final typedPatterns: Array<TypedCustomSyntaxDeclarationPattern> = [];
		for(pattern in untypedCustomSyntax.value.patterns) {
			final type = switch(TypeTyper.typeType(typer, pattern.returnType)) {
				case Success(type): type;
				case Error(typeErrors): {
					errors.pushArray(typeErrors);
					continue;
				}
			}

			typedPatterns.push({
				type: {
					value: type, position: pattern.returnType.position
				},
				id: pattern.id
			});

			for(token in pattern.tokenPattern) {
				switch(token) {
					case ExpressionInput(name, inputKind): {
						// Convert `UntypedExpressionInputKind` to `TypedExpressionInputKind`.
						final type: TypedExpressionInputKind = switch(inputKind.value) {
							case UntypedExpressionInput(type): {
								switch(TypeTyper.typeType(typer, inputKind.map(_ -> type))) {
									case Success(type): TypedExpressionInput(type);
									case Error(typeErrors): {
										errors.pushArray(typeErrors);
										continue;
									}
								}
							}
							case CustomSyntaxInput(id): {
								CustomSyntaxInput(id, false);
							}
						}

						// Store the "type" of this input.
						// If it already exists, increment the counter if it matches the previous
						// type, or generate an error if not.
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

		// Generate a list of the inputs.
		// For the ones that don't exist in all patterns, make them nullable.
		final inputs: Array<{ name: String, type: TypedExpressionInputKind }> = [];
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
					untypedCustomSyntax.value.name, ucs.id, scope, inputs, typedPatterns
				);
			})
		);
	}
}
