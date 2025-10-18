package sillyscript.compiler.parser.custom_syntax;

import sillyscript.compiler.parser.AmbiguousType;
import haxe.ds.ReadOnlyArray;
import sillyscript.compiler.lexer.Token;
import sillyscript.compiler.parser.UntypedAst.UntypedDeclaration;

/**
	A unique identifier for a custom syntax that is not compatible with other `Int`s.
**/
abstract CustomSyntaxId(Int) from Int {}

/**
	Bruh this is literally the same thing as above but for custom syntax patterns.
	What? Am I just supposed to repeat the exact same documentation that's RIGHT THERE??
**/
abstract CustomSyntaxPatternId(Int) from Int {}

/**
	Stores whether the input is a specific type or a custom syntax.
**/
enum UntypedExpressionInputKind {
	UntypedExpressionInput(type: AmbiguousType);
	CustomSyntaxInput(id: CustomSyntaxId);
}

/**
	Represents a token in a custom syntax declaration.
**/
enum CustomSyntaxDeclarationToken {
	/**
		`name` is the name of the expression input parameter.
		`type` is the required type of the expression.
	**/
	ExpressionInput(name: Positioned<String>, type: Positioned<UntypedExpressionInputKind>);

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
	static var maxId: Int = 0;

	public var returnType(default, null): Positioned<AmbiguousType>;
	public var tokenPattern(default, null): ReadOnlyArray<CustomSyntaxDeclarationToken>;
	public var id(default, null): CustomSyntaxPatternId;

	public function new(
		returnType: Positioned<AmbiguousType>,
		tokenPattern: ReadOnlyArray<CustomSyntaxDeclarationToken>
	) {
		this.returnType = returnType;
		this.tokenPattern = tokenPattern;
		id = maxId++;
	}
}

/**
	Represents a custom syntax declaration prior to the typing phase.
**/
class UntypedCustomSyntaxDeclaration {
	static var maxId: Int = 0;

	public static function deferred() {
		return new UntypedCustomSyntaxDeclaration({ value: "", position: Position.INVALID }, [], []);
	}

	// ---

	public var name(default, null): Positioned<String>;
	public var declarations(default, null): ReadOnlyArray<Positioned<UntypedDeclaration>>;
	public var patterns(default, null): ReadOnlyArray<UntypedCustomSyntaxDeclarationPattern>;
	public var id(default, null): CustomSyntaxId;

	public function new(
		name: Positioned<String>,
		declarations: ReadOnlyArray<Positioned<UntypedDeclaration>>,
		patterns: ReadOnlyArray<UntypedCustomSyntaxDeclarationPattern>
	) {
		setAll(name, declarations, patterns);
		id = maxId++;
	}

	public inline function setAll(
		name: Positioned<String>,
		declarations: ReadOnlyArray<Positioned<UntypedDeclaration>>,
		patterns: ReadOnlyArray<UntypedCustomSyntaxDeclarationPattern>
	) {
		this.name = name;
		this.declarations = declarations;
		this.patterns = patterns;
	}
}
