package sillyscript.compiler.typer.subtyper;

import sillyscript.compiler.parser.UntypedAst;
import haxe.ds.ReadOnlyArray;
import sillyscript.compiler.parser.custom_syntax.CustomSyntaxScope.CustomSyntaxScopeMatchResultExpression;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration.CustomSyntaxId;
import sillyscript.compiler.typer.ast.TypedCustomSyntaxDeclaration;
import sillyscript.compiler.typer.Typer.TyperResult;
import sillyscript.compiler.Result.PositionedResult;
using sillyscript.extensions.ArrayExt;

/**
	A pairing of a name and typed expression used to represent an input for a custom syntax. 
**/
typedef CustomSyntaxNamedExpression = { key: Positioned<String>, value: Positioned<TypedAst> };

/**
	Types an untyped AST expression of `CustomSyntax` to a `TypedAst` of `CustomSyntax`.
**/
class CustomSyntaxExprTyper {
	/**
		Types the fields of an `UntypedAst` of `CustomSyntax`.
	**/
	public static function type(
		typer: Typer,
		ast: Positioned<UntypedAst>,
		candidates: Array<CustomSyntaxId>,
		expressions: Array<CustomSyntaxScopeMatchResultExpression>
	): TyperResult {
		// Type the input expressions
		final result = extractTypedExpressionsFromCustomSyntax(typer, expressions);
		final typedExpressions = switch(result) {
			case Success(typedExpressions): typedExpressions;
			case Error(e): return Error(e);
		}

		// Collect the matching type candidate instances (and a map of their expression identifiers)
		var newCandidateDeclarations: Array<TypedCustomSyntaxDeclaration>;
		var identifiedExpressions: Map<CustomSyntaxId, Array<CustomSyntaxNamedExpression>>;
		switch(findCandidateDeclarations(typer, candidates, expressions, typedExpressions)) {
			case Success({
				newCandidateDeclarations: _newCandidateDeclarations,
				identifiedExpressions: _identifiedExpressions
			}): {
				newCandidateDeclarations = _newCandidateDeclarations;
				identifiedExpressions = _identifiedExpressions;
			}
			case Error(e): return Error(e);
		}

		// If multiple valid candidates pass typing, error...
		if(newCandidateDeclarations.length > 1) {
			final candidateNames = newCandidateDeclarations.map(function(customSyntax) {
				return customSyntax.name.value;
			});
			return Error([{
				value: AmbiguousCustomSyntaxCandidates(candidateNames),
				position: ast.position
			}]);
		}

		// If none pass typing, but there was only one input candidate, error...
		if(newCandidateDeclarations.length == 0 && candidates.length == 1) {
			final syntax = typer.findTypedCustomSyntaxDeclaration(candidates[0]);
			return Error([{
				value: InvalidTypesForCustomSyntax(syntax),
				position: ast.position
			}]);
		}

		// If none pass typing, but there were multiple input candidates, error...
		if(newCandidateDeclarations.length == 0 && candidates.length > 1) {
			final syntaxes: Array<TypedCustomSyntaxDeclaration> = [];
			for(candidate in candidates) {
				final syntax = typer.findTypedCustomSyntaxDeclaration(candidate);
				if(syntax != null) {
					syntaxes.push(syntax);
				}
			}
			return Error([{
				value: InvalidTypesForMultipleCustomSyntaxCandidates(syntaxes),
				position: ast.position
			}]);
		}

		// Get the guaranteed one candidate
		final candidate = newCandidateDeclarations.get(0);
		if(candidate == null) {
			return Error([{
				value: CompilerError("final custom syntax candidate does not exist"),
				position: ast.position
			}]);
		}

		// Get its identified expressions
		final expressions = identifiedExpressions.get(candidate.id);
		if(expressions == null) {
			return Error([{
				value: CompilerError("final custom syntax candidate's identified expressions do not exist"),
				position: ast.position
			}]);
		}

		// Return a typed `CustomSyntax` `TypedAst`!
		return Success({
			value: CustomSyntax(candidate, expressions),
			position: ast.position
		});
	}

	/**
		Type the expressions from the `CustomSyntax` and provide both their `TypedAst` and
		`SillyType`.
	**/
	static function extractTypedExpressionsFromCustomSyntax(
		typer: Typer,
		expressions: ReadOnlyArray<CustomSyntaxScopeMatchResultExpression>
	): PositionedResult<Array<{ typedExpression: Positioned<TypedAst>, type: SillyType }>, TyperError> {
		final typedExpressions: Array<{ typedExpression: Positioned<TypedAst>, type: SillyType }> = [];
		final errors: Array<Positioned<TyperError>> = [];
		for(e in expressions) {
			switch(typer.typeAst(e.expression)) {
				case Success(typedAst): {
					typedExpressions.push({
						typedExpression: typedAst,
						type: switch(SillyType.fromTypedAst(typedAst)) {
							case Success(type): type;
							case Error(e): return Error(e);
						}
					});
				}
				case Error(typingErrors): {
					for(error in typingErrors) {
						errors.push(error);
					}
				}
			}
		}

		if(errors.length > 0) {
			return Error(errors);
		}

		return Success(typedExpressions);
	}

	/**
		Find all possible custom syntax declarations based on whether their types are compatible
		with the expressions provided.
	**/
	static function findCandidateDeclarations(
		typer: Typer,
		candidates: ReadOnlyArray<CustomSyntaxId>,
		expressions: ReadOnlyArray<CustomSyntaxScopeMatchResultExpression>,
		typedExpressions: ReadOnlyArray<{ typedExpression: Positioned<TypedAst>, type: SillyType }>
	): PositionedResult<{
		newCandidateDeclarations: Array<TypedCustomSyntaxDeclaration>,
		identifiedExpressions: Map<CustomSyntaxId, Array<CustomSyntaxNamedExpression>>
	}, TyperError> {
		final errors = [];
		final newCandidateDeclarations: Array<TypedCustomSyntaxDeclaration> = [];
		final identifiedExpressions:
			Map<CustomSyntaxId, Array<CustomSyntaxNamedExpression>> = [];

		for(candidate in candidates) {
			switch(checkCustomSyntaxCandidate(
				typer, candidate, identifiedExpressions, expressions, typedExpressions
			)) {
				case Success(newCandidates): {
					for(c in newCandidates) {
						newCandidateDeclarations.push(c);
					}
				}
				case Error(candidateCheckErrors): {
					for(e in candidateCheckErrors) {
						errors.push(e);
					}
				}
			}
		}

		if(errors.length > 0) {
			return Error(errors);
		}

		return Success({
			newCandidateDeclarations: newCandidateDeclarations,
			identifiedExpressions: identifiedExpressions
		});
	}

	/**
		Checks whether the types match for an individual custom syntax candidate.
	**/
	static function checkCustomSyntaxCandidate(
		typer: Typer,
		candidate: CustomSyntaxId,
		identifiedExpressions: Map<CustomSyntaxId, Array<CustomSyntaxNamedExpression>>,
		expressions: ReadOnlyArray<CustomSyntaxScopeMatchResultExpression>,
		typedExpressions: ReadOnlyArray<{ typedExpression: Positioned<TypedAst>, type: SillyType }>
	): PositionedResult<Array<TypedCustomSyntaxDeclaration>, TyperError> {
		final newCandidates: Array<TypedCustomSyntaxDeclaration> = [];

		final syntax = typer.findTypedCustomSyntaxDeclaration(candidate);
		if(syntax == null) {
			// TODO: Should this be an error??
			return Success([]);
		}

		final identifyExpressions = identifiedExpressions.get(candidate) ?? {
			final result = [];
			identifiedExpressions.set(candidate, result);
			result;
		};

		// Check the types for each expression...
		var valid = true;
		final inputs = syntax.inputsAsMap();
		for(i in 0...expressions.length) {
			final expression = expressions[i];
			final typedExpression = typedExpressions[i];

			final identifier = expression.identifiers.get(candidate);
			if(identifier == null) {
				return Error([{
					value: CompilerError("identifier for custom syntax could not be found in match result expression"),
					position: expression.expression.position
				}]);
			}

			final candidateDesiredType = inputs.get(identifier);
			if(candidateDesiredType == null) {
				return Error([{
					value: CompilerError("the type of the input expression could not be found when checking validity of custom syntax candidate"),
					position: expression.expression.position
				}]);
			}

			identifyExpressions.push({
				key: {
					value: identifier,
					position: typedExpression.typedExpression.position
				},
				value: typedExpression.typedExpression
			});

			switch(candidateDesiredType.canReceiveType(typedExpression.type)) {
				case Success(true): {}
				case _: {
					valid = false;
					break;
				}
			}
		}

		if(valid) {
			newCandidates.push(syntax);
		}

		return Success(newCandidates);
	}
}
