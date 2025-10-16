package sillyscript.compiler.typer.subtyper;

import sillyscript.compiler.parser.UntypedAst.UntypedDefDeclaration;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.compiler.typer.ast.Scope;
import sillyscript.compiler.typer.ast.TypedDef;
import sillyscript.compiler.typer.TyperError;
import sillyscript.extensions.Nothing;
import sillyscript.Positioned;
using sillyscript.extensions.ArrayExt;

/**
	Handles the typing of `def` declarations.
**/
@:access(sillyscript.compiler.parser.Parser)
class DefDeclTyper {
	/**
		Types an untyped `def` declaration.
	**/
	public static function type(
		typer: Typer,
		untypedDef: Positioned<UntypedDefDeclaration>
	): PositionedResult<Positioned<TypedDef>, TyperError> {
		final errors = [];

		final typedArguments: Array<Positioned<TypedDefArgument>> = [];
		for(argument in untypedDef.value.arguments) {
			final realType = switch(TypeTyper.typeType(typer, argument.value.type)) {
				case Success(type): type;
				case Error(typingErrors): {
					errors.pushArray(typingErrors);
					continue;
				}
			}

			final typedDefaultValue = if(argument.value.defaultValue != null) {
				switch(typer.typeAst(argument.value.defaultValue)) {
					case Success(typedAst): typedAst;
					case Error(typeErrors): {
						errors.pushArray(typeErrors);
						null;
					}
				}
			} else {
				null;
			}

			if(typedDefaultValue != null) {
				switch(SillyType.fromTypedAst(typedDefaultValue)) {
					case Success(type): {
						switch(realType.canReceiveType(type)) {
							case Success(Nothing): {}
							case Error(typeErrors): {
								errors.pushArray(typeErrors.map(e -> ({
									value: e, position: argument.position
								} : Positioned<TyperError>)));
							}
						}
					}
					case Error(typeErrors): errors.pushArray(typeErrors);
				}
			}

			typedArguments.push({
				value: {
					name: argument.value.name,
					type: {
						value: realType,
						position: argument.value.type.position
					},
					defaultValue: typedDefaultValue
				},
				position: argument.position
			});
		}

		if(errors.length > 0) {
			return Error(errors);
		}

		final returnTypeTypingResult = TypeTyper.typeType(typer, untypedDef.value.returnType);
		final realReturnType: Positioned<SillyType> = switch(returnTypeTypingResult) {
			case Success(type): {
				value: type,
				position: untypedDef.position
			}
			case Error(typeErrors): {
				errors.pushArray(typeErrors);
				return Error(errors);
			}
		}

		final typedDef = new TypedDef(
			untypedDef.value.name,
			typedArguments,
			realReturnType
		);

		final scope = new Scope();
		scope.addContainedInDefs({ value: typedDef, position: untypedDef.position });
		typer.pushScope(scope);
		final typingResult = typer.typeAst(untypedDef.value.content);
		typer.popScope();

		return switch(typingResult) {
			case Success(defExpression): {
				switch(checkReturnType(defExpression, untypedDef, realReturnType.value)) {
					case Success(Nothing): {}
					case Error(e): return Error(e);
				}

				typedDef.setContent(defExpression);
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

	/**
		Returns `Success` if the return type of the `def`'s value can be passed to its return type.
		Returns the `Error` that explains why it cannot otherwise.
	**/
	static function checkReturnType(
		defExpression: Positioned<TypedAst>,
		untypedDef: Positioned<UntypedDefDeclaration>,
		returnType: SillyType
	): PositionedResult<Nothing, TyperError> {
		switch(SillyType.fromTypedAst(defExpression)) {
			case Success(defExpressionType): {
				switch(returnType.canReceiveType(defExpressionType)) {
					case Success(Nothing): {}
					case Error(errors): return Error(errors.map(function(e) {
						final e = switch(e) {
							case WrongType(receivingType, providingType): {
								WrongReturnType(receivingType, providingType);
							}
							case e: e;
						}
						return ({
							value: e,
							position: untypedDef.position
						} : Positioned<TyperError>);
					}));
				}
			}
			case Error(errors): return Error(errors);
		}

		return Success(Nothing);
	}
}
