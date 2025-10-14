package sillyscript.compiler.typer;

import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration.CustomSyntaxId;
import sillyscript.compiler.parser.UntypedAst;
import sillyscript.compiler.Result.PositionedResult;
import sillyscript.compiler.typer.ast.Scope;
import sillyscript.compiler.typer.ast.TypedCustomSyntaxDeclaration;
import sillyscript.compiler.typer.subtyper.CallTyper;
import sillyscript.compiler.typer.subtyper.CustomSyntaxExprTyper;
import sillyscript.compiler.typer.subtyper.DeclarationTyper;
import sillyscript.compiler.typer.TypedAst.TypedDictionaryEntry;
import sillyscript.compiler.typer.TyperError;
import sillyscript.extensions.Stack;
import sillyscript.Positioned;

/**
	The resulting type used by the `Typer`.
**/
typedef TyperResult = PositionedResult<Positioned<TypedAst>, TyperError>;

/**
	Converts `UntypedAst` instances to `TypedAst`.
**/
class Typer {
	var untypedAst: Positioned<UntypedAst>;
	var context: Context;
	var errors: Array<Positioned<TyperError>>;
	var scopeStack: Stack<Scope>;

	/**
		Constructor.
	**/
	public function new(untypedAst: Positioned<UntypedAst>, context: Context) {
		this.untypedAst = untypedAst;
		this.context = context;

		errors = [];
		scopeStack = [];
	}

	public function pushScope(scope: Scope) {
		scopeStack.pushTop(scope);
	}

	public function popScope() {
		scopeStack.popTop();
	}

	/**
		Returns the `TypedCustomSyntaxDeclaration` for the `id` `CustomSyntaxId` if it exists in 
		this scope.
	**/
	public function findTypedCustomSyntaxDeclaration(id: CustomSyntaxId): Null<TypedCustomSyntaxDeclaration> {
		for(scope in scopeStack.topToBottomIterator()) {
			final maybeSyntax = scope.findCustomSyntax(id);
			if(maybeSyntax != null) {
				return maybeSyntax;
			}
		}
		return null;
	}

	/**
		Returns the `TypedAst` of the `untypedAst` passed in the constructor.
	**/
	public function type(): TyperResult {
		return typeAst(untypedAst);
	}

	/**
		Converts an `UntypedAst` to `TypedAst`.
	**/
	public function typeAst(ast: Positioned<UntypedAst>): TyperResult {
		return switch(ast.value) {
			case Identifier(name): {
				for(scope in scopeStack.topToBottomIterator()) {
					switch(scope.findIdentifier(name)) {
						case Def(def): {
							return Success({
								value: DefIdentifier(def),
								position: ast.position
							});
						}
						case DefArgument(def, index): {
							return Success({
								value: DefArgumentIdentifier(def, index),
								position: ast.position
							});
						}
						case _:
					}
				}

				return Error([{
					value: NothingWithName(name),
					position: ast.position
				}]);
			}
			case Value(value): {
				Success({
					value: Value(value),
					position: ast.position
				});
			}
			case List({
				items: items, scope: scope
			}): {
				final typedEntries = [];
				final errors = [];
				final scope = DeclarationTyper.type(this, scope.declarations, errors);

				pushScope(scope);
				for(item in items) {
					switch(typeAst(item)) {
						case Success(typedAst): typedEntries.push(typedAst);
						case Error(itemErrors): for(e in itemErrors) errors.push(e);
					}
				}
				popScope();

				if(errors.length > 0) {
					Error(errors);
				} else {
					Success({
						value: List(typedEntries, scope),
						position: ast.position
					});
				}
			}
			case Dictionary({
				items: items, scope: scope
			}): {
				final typedEntries: Array<Positioned<TypedDictionaryEntry>> = [];
				final errors = [];
				final scope = DeclarationTyper.type(this, scope.declarations, errors);

				pushScope(scope);
				for(item in items) {
					switch(typeAst(item.value.value)) {
						case Success(typedAst): typedEntries.push({
							value: { key: item.value.key, value: typedAst },
							position: item.position
						});
						case Error(itemErrors): for(e in itemErrors) errors.push(e);
					}
				}
				popScope();

				if(errors.length > 0) {
					Error(errors);
				} else {
					Success({
						value: Dictionary(typedEntries, scope),
						position: ast.position
					});
				}
			}
			case Call(calledAst, arguments): {
				CallTyper.type(this, ast, calledAst, arguments);
			}
			case CustomSyntax(candidates, expressions): {
				CustomSyntaxExprTyper.type(this, ast, candidates, expressions);
			}
		}
	}
}
