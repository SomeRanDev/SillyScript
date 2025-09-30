package sillyscript.compiler;

enum Value {
	Null;
	Bool(value: Bool);
	Int(content: String);
	Float(content: String);
	String(content: String);
}
