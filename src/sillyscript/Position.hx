package sillyscript;

@:structInit
class Position {
	public var fileIdentifier(default, null): Int;
	public var start(default, null): Int;
	public var end(default, null): Int;

	public function merge(other: Position): Position {
		return {
			fileIdentifier: fileIdentifier,
			start: start < other.start ? start : other.start,
			end: end > other.end ? end : other.end,
		};
	}

	public function toString() {
		return fileIdentifier + "(" + start + "-" + end + ")";
	}
}
