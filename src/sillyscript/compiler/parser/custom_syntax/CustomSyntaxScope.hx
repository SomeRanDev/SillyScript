package sillyscript.compiler.parser.custom_syntax;

import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.compiler.parser.subparsers.ExpressionParser;
import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration;

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

	public function new() {
		startingNode = new CustomSyntaxNode(null);
	}

	/**
		Pushes a scope for custom syntax that can be popped later.
	**/
	public function pushScope() {
		startingNode.pushScope();
	}

	/**
		Pops the current custom syntax scope.
	**/
	public function popScope() {
		startingNode.popScope();
	}

	/**
		Adds a custom syntax to the tree of nodes.
	**/
	public function addSyntaxDeclaration(declaration: Positioned<UntypedCustomSyntaxDeclaration>) {
		for(i in 0...declaration.value.patterns.length) {
			final pattern = declaration.value.patterns[i];
			if(pattern.tokenPattern.length <= 0) continue;

			var currentNode: CustomSyntaxNode = startingNode;
			for(token in pattern.tokenPattern) {
				var csToken = switch(token) {
					case ExpressionInput(_, _): CustomSyntaxToken.Expression;
					case Token(token): CustomSyntaxToken.Token(token);
				}
				currentNode = currentNode.findOrCreateNextNode(csToken);
				switch(token) {
					case ExpressionInput(name, _): {
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
		preparsedExpression: Null<Positioned<UntypedAst>>
	): ParseResult<CustomSyntaxScopeMatchResult> {
		final parser = context.parser;
		final expressions: Array<CustomSyntaxScopeMatchResultExpression> = [];

		var node = startingNode;
		var token = parser.peek();
		while(token != null && token != EndOfFile) {
			// If `preparedExpression` isn't `null`, let's set `newNode` to `null` to FORCE the
			// code to check for expression next node instead.
			var newNode = if(preparsedExpression != null) {
				null;
			} else {
				node.getNextNodeFromCurrentToken(token);
			}
			var advance = true;
			if(newNode == null) {
				if(node.hasExpressionNextNode()) {
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
								ExpressionParser.parseListOrDictionaryPostColonIdent(parser);
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
