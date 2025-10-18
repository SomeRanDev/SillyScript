package sillyscript.compiler.parser.custom_syntax;

import haxe.ds.Either;
import sillyscript.extensions.Stack;
import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.compiler.parser.subparsers.ExpressionParser;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration;
using sillyscript.extensions.ArrayExt;

/**
	Stores the results from `CustomSyntaxScope.matchSyntax`.
**/
@:structInit
class CustomSyntaxScopeMatchResult {
	/**
		A list of candidates that match the parsed syntax.

		`id` is the ID of the custom syntax.
		`patternIndex` is the index of the pattern that was matched.
	**/
	public var possibilities(default, null): Array<{ id: CustomSyntaxId, patternIndex: Int }>;

	/**
		A list of expressions parsed while parsing the custom syntax.
	**/
	public var expressions(default, null): Array<CustomSyntaxScopeMatchResultExpression>;
}

/**
	Used internally for `CustomSyntaxScopeMatchResult.expressions`.
**/
@:structInit
class CustomSyntaxScopeMatchResultExpression {
	/**
		The untyped expression AST that was parsed.
	**/
	public var expression(default, null): Positioned<UntypedAst>;

	/**
		A map of all the identifiers this expression correlates to with custom syntax declarations.
	**/
	public var identifiers(default, null): Map<CustomSyntaxId, String>;
}

/**
	A class that manages the scope for custom syntax during parsing.
**/
class CustomSyntaxScope {
	/**
		This is the starting node all the syntaxes created in this scope are added to.
	**/
	var startingNode: CustomSyntaxNode;

	/**
		A stack of the available syntax declarations.
	**/
	var syntaxStack: Stack<Array<Positioned<UntypedCustomSyntaxDeclaration>>>;

	public function new() {
		startingNode = new CustomSyntaxNode(null);
		syntaxStack = [[]];
	}

	/**
		Pushes a scope for custom syntax that can be popped later.
	**/
	public function pushScope() {
		startingNode.pushScope();
		syntaxStack.pushTop([]);
	}

	/**
		Pops the current custom syntax scope.
	**/
	public function popScope() {
		startingNode.popScope();
		syntaxStack.popTop();
	}

	/**
		Given `name`, returns the untyped custom syntax declaration available from the parser's 
		current scope.
	**/
	public function findSyntaxDeclaration(name: String): Null<Positioned<UntypedCustomSyntaxDeclaration>> {
		for(syntaxList in syntaxStack.topToBottomIterator()) {
			for(syntax in syntaxList) {
				if(syntax.value.name.value == name) {
					return syntax;
				}
			}
		}
		return null;
	}

	/**
		Given `CustomSyntaxId`, returns the untyped custom syntax declaration available from the
		parser's current scope.
	**/
	public function findSyntaxDeclarationById(id: CustomSyntaxId): Null<Positioned<UntypedCustomSyntaxDeclaration>> {
		for(syntaxList in syntaxStack.topToBottomIterator()) {
			for(syntax in syntaxList) {
				if(syntax.value.id == id) {
					return syntax;
				}
			}
		}
		return null;
	}

	/**
		Adds a custom syntax to the tree of nodes.
	**/
	public function addSyntaxDeclaration(declaration: Positioned<UntypedCustomSyntaxDeclaration>) {
		syntaxStack.last()?.push(declaration);

		for(i in 0...declaration.value.patterns.length) {
			final pattern = declaration.value.patterns[i];
			if(pattern.tokenPattern.length <= 0) continue;

			var currentNode: CustomSyntaxNode = startingNode;
			for(token in pattern.tokenPattern) {
				var csToken = switch(token) {
					case ExpressionInput(_, _): CustomSyntaxToken.Expression;
					case CustomSyntaxInput(_, id): CustomSyntaxToken.Syntax(id);
					case Token(token): CustomSyntaxToken.Token(token);
				}
				currentNode = currentNode.findOrCreateNextNode(csToken);
				switch(token) {
					case ExpressionInput(name, _): {
						currentNode.pushDeclarationExpressionIdentifier(declaration.value.id, name.value);
					}
					case CustomSyntaxInput(name, _): {
						currentNode.pushDeclarationExpressionIdentifier(declaration.value.id, name.value);
					}
					case _:
				}
			}

			if(currentNode != startingNode) {
				currentNode.addCustomSyntaxEndCandidate(declaration.value.id, i);
			}
		}
	}

	/**
		Attempts to parse one of the available custom syntaxes.

		If `preparsedExpression` is not `null`, we assume an expression has already been parsed
		and it should be treated as the first "token" for a custom syntax. If there is no initial
		"expression" token node, then return `NoMatch`.
	**/
	public function matchSyntax(
		context: ExpressionParserContext,
		preparsedContent: Null<Either<Positioned<UntypedAst>, { id: CustomSyntaxId, expression: Positioned<UntypedAst> }>>
	): ParseResult<CustomSyntaxScopeMatchResult> {
		final parser = context.parser;
		final expressions: Array<CustomSyntaxScopeMatchResultExpression> = [];

		var tokensParsed = 0;
		var node = startingNode;
		var token = parser.peek();
		while(token != null && token != EndOfFile) {
			// If `preparsedContent` isn't `null`, let's set `newNode` to `null` to FORCE the
			// code to check for expression next node instead.
			var newNode = if(preparsedContent != null) {
				null;
			} else {
				node.getNextNodeFromCurrentToken(token);
			}
			var advance = true;
			if(newNode == null) {
				var preparsedExpression = null;
				var preparsedSyntax = null;
				if(preparsedContent != null) {
					switch(preparsedContent) {
						case Left(expr): preparsedExpression = expr;
						case Right(syntaxData): preparsedSyntax = syntaxData;
						case _:
					}
					preparsedContent = null;
				}

				final ids = node.getAllSyntaxNextNodeIds();

				final allowSyntax = tokensParsed > 0 || preparsedSyntax != null;
				if(allowSyntax && ids != null && ids.length > 0) {
					final result: ParseResult<Positioned<UntypedAst>> = if(preparsedSyntax != null && ids.contains(preparsedSyntax.id)) {
						final result = preparsedSyntax;
						preparsedSyntax = null;
						Success(result.expression);
					} else {
						switch(matchSyntax(context, null)) {
							case Success(result): {
								final newPossibilities = [];
								for(possibility in result.possibilities) {
									if(ids.contains(possibility.id)) {
										newPossibilities.push(possibility);
									}
								}
								if(newPossibilities.length > 0) {
									Success({
										value: CustomSyntax(newPossibilities, result.expressions),
										position: Position.INVALID
									});
								} else {
									NoMatch;
								}
							}
							case NoMatch: NoMatch;
							case Error(errors): Error(errors);
						}
					}

					switch(result) {
						case Success(result): {
							advance = false;

							final candidateSyntaxIds = [];
							switch(result.value) {
								case CustomSyntax(candidates, _): {
									for(candidate in candidates) {
										if(!candidateSyntaxIds.contains(candidate.id)) {
											candidateSyntaxIds.push(candidate.id);
										}
									}
								}
								case _:
							}

							final id = candidateSyntaxIds.get(0);
							if(id == null || candidateSyntaxIds.length != 1) {
								return Error([{
									value: AmbiguousCustomSyntaxInCustomSyntax(candidateSyntaxIds),
									position: result.position
								}]);
							}

							newNode = node.getSyntaxNextNode(id);
							if(newNode != null) {
								expressions.push({
									expression: result,
									identifiers: newNode.getDeclarationExpressionIdentifierMap()
								});
							}
						}
						case NoMatch: return NoMatch;
						case Error(e): return Error(e);
					}
				}

				// Only allow an expression node if its NOT the first token UNLESS
				// `preparsedExpression` is provided.
				final allowExpression = tokensParsed > 0 || preparsedExpression != null;
				if(allowExpression && node.hasExpressionNextNode()) {
					// If `preparsedExpression` isn't `null`, let's use that first!
					final result = if(preparsedExpression != null) {
						final result = preparsedExpression;
						preparsedExpression = null;
						Success(result);
					} else {
						switch(parser.peek(-1)) {
							case Colon: {
								ExpressionParser.parseExpression(context, true);
							}
							case IncrementIndent if(parser.peek(-2) == Colon): {
								ExpressionParser.parseListOrDictionaryPostColonIdent(context);
							}
							case _: {
								ExpressionParser.parseExpression(context, false);
							}
						}
					}

					switch(result) {
						case Success(result): {
							advance = false;
							newNode = node.getExpressionNextNode();
							if(newNode != null) {
								expressions.push({
									expression: result,
									identifiers: newNode.getDeclarationExpressionIdentifierMap()
								});
							}
						}
						case NoMatch: return NoMatch;
						case Error(e): return Error(e);
					}
				}
			}

			if(newNode == null) {
				break;
			}

			if(advance) {
				parser.advance();
			}

			node = newNode;
			token = parser.peek();
			tokensParsed++;
		}

		if(node == null || node == startingNode) {
			return NoMatch;
		}

		final possibilities = node.findCustomSyntaxEndCandidates();

		if(possibilities.length <= 0) {
			return NoMatch;
		}

		return Success({
			possibilities: possibilities,
			expressions: expressions
		});
	}
}
