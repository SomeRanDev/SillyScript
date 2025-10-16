package sillyscript;

@:structInit
class Position {
	public static final INVALID: Position = { fileIdentifier: -1, start: -1, end: -1 };

	public var fileIdentifier(default, null): Int;
	public var start(default, null): Int;
	public var end(default, null): Int;

	public function merge(other: Position): Position {
		if(fileIdentifier < 0 || other.fileIdentifier < 0) {
			return INVALID;
		}
		return {
			fileIdentifier: fileIdentifier,
			start: start < other.start ? start : other.start,
			end: end > other.end ? end : other.end,
		};
	}

	public function toString() {
		if(fileIdentifier < 0) {
			return "Position(INVALID)";
		}
		return "Position(" + fileIdentifier + ", (" + start + "-" + end + "))";
	}
}
