package sillyscript.compiler;

class Context {
	public var fileIdentifier(default, null): Int;

	public function new(fileIdentifier: Int) {
		this.fileIdentifier = fileIdentifier;
	}
}
