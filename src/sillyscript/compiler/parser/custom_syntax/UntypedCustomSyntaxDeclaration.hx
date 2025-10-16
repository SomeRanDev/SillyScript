package sillyscript.compiler.parser.custom_syntax;

import sillyscript.compiler.parser.AmbiguousType;
import haxe.ds.ReadOnlyArray;
import sillyscript.compiler.lexer.Token;
import sillyscript.compiler.parser.UntypedAst.UntypedDeclaration;

typedef CustomSyntaxId = Int;

/**
	Represents a token in a custom syntax declaration.
**/
enum CustomSyntaxDeclarationToken {
	/**
		`name` is the name of the expression input parameter.
		`type` is the required type of the expression.
	**/
	ExpressionInput(name: Positioned<String>, type: Positioned<AmbiguousType>);

	/**
		`token` is any token that isn't a part of an expression input.
	**/
	Token(token: Token);
}

/**
	Represents a `pattern` declaration within a custom syntax declaration.
**/
@:structInit
class UntypedCustomSyntaxDeclarationPattern {
	public var returnType(default, null): Positioned<AmbiguousType>;
	public var tokenPattern(default, null): ReadOnlyArray<CustomSyntaxDeclarationToken>;
}

/**
	Represents a custom syntax declaration prior to the typing phase.
**/
class UntypedCustomSyntaxDeclaration {
	static var maxId: Int = 0;

	public var name(default, null): Positioned<String>;
	public var declarations(default, null): ReadOnlyArray<Positioned<UntypedDeclaration>>;
	public var patterns(default, null): ReadOnlyArray<UntypedCustomSyntaxDeclarationPattern>;
	public var id(default, null): CustomSyntaxId;

	public function new(
		name: Positioned<String>,
		declarations: ReadOnlyArray<Positioned<UntypedDeclaration>>,
		patterns: ReadOnlyArray<UntypedCustomSyntaxDeclarationPattern>
	) {
		this.name = name;
		this.declarations = declarations;
		this.patterns = patterns;

		id = maxId++;
	}
}
