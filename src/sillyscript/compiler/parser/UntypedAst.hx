package sillyscript.compiler.parser;

import sillyscript.compiler.parser.custom_syntax.UntypedCustomSyntaxDeclaration;
import sillyscript.compiler.parser.custom_syntax.CustomSyntaxScope;
import sillyscript.Positioned;

typedef UntypedDictionaryEntry = { key: Positioned<String>, value: Positioned<UntypedAst> };

/**
	Untyped syntax tree.
**/
enum UntypedAst {
	Identifier(name: String);
	Value(value: Value);
	List(untypedList: UntypedList);
	Dictionary(untypedDictionary: UntypedDictionary);
	Call(calledAst: Positioned<UntypedAst>, arguments: Array<{ name: Null<String>, value: Positioned<UntypedAst> }>);
	CustomSyntax(candidates: Array<{ id: CustomSyntaxId, patternIndex: Int }>, expressions: Array<CustomSyntaxScopeMatchResultExpression>);
}

@:structInit
class UntypedDictionary {
	public var items(default, null): Array<Positioned<UntypedDictionaryEntry>>;
	public var scope(default, null): UntypedScope;
}

@:structInit
class UntypedList {
	public var items(default, null): Array<Positioned<UntypedAst>>;
	public var scope(default, null): UntypedScope;
}

enum UntypedDeclaration {
	Def(def: UntypedDefDeclaration);
	Enum(enumDecl: UntypedEnumDeclaration);
	CustomSyntax(customSyntax: UntypedCustomSyntaxDeclaration);
}

@:structInit
class UntypedScope {
	public var declarations(default, null): Array<Positioned<UntypedDeclaration>>;
	public var syntaxScope(default, null): Null<CustomSyntaxScope>;
}

typedef UntypedDefArgument = {
	name: Positioned<String>,
	type: Positioned<AmbiguousType>,
	defaultValue: Null<Positioned<UntypedAst>>
};

@:structInit
class UntypedDefDeclaration {
	public var name(default, null): String;
	public var arguments(default, null): Array<Positioned<UntypedDefArgument>>;
	public var returnType(default, null): Positioned<AmbiguousType>;
	public var content(default, null): Positioned<UntypedAst>;

	public function toString() {
		return '{ name: $name, arguments: $arguments, returnType: $returnType, content: $content }';
	}
}

@:structInit
class UntypedEnumDeclaration {
	public var name(default, null): Positioned<String>;
	public var type(default, null): Null<Positioned<AmbiguousType>>;
	public var cases(default, null): Array<Positioned<String>>;

	public function toString() {
		return 'UntypedEnumDeclaration(name: $name, type: $type, cases: $cases)';
	}
}
