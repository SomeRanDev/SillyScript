package sillyscript;

@:structInit
class Position {
	public static final INVALID: Position = { fileIdentifier: -1, start: -1, end: -1 };

	public static function deferred(placeholder: Position): Position {
		final result: Position = {
			fileIdentifier: placeholder.fileIdentifier,
			start: placeholder.start,
			end: placeholder.end
		};
		result.isDeferred = true;
		return result;
	}

	public var fileIdentifier(default, null): Int;
	public var start(default, null): Int;
	public var end(default, null): Int;

	var isDeferred: Bool = false;

	public function merge(other: Position): Position {
		if(isDeferred || other.isDeferred) {
			return INVALID;
		}
		if(fileIdentifier < 0 || other.fileIdentifier < 0) {
			return INVALID;
		}
		return {
			fileIdentifier: fileIdentifier,
			start: start < other.start ? start : other.start,
			end: end > other.end ? end : other.end,
		};
	}

	public function undefer(newPosition: Position) {
		if(!isDeferred) return;
		fileIdentifier = newPosition.fileIdentifier;
		start = newPosition.start;
		end = newPosition.end;
		isDeferred = false;
	}

	public function toString() {
		if(fileIdentifier < 0) {
			return "Position(INVALID)";
		}
		return (isDeferred ? "Deferred" : "") + "Position(" + fileIdentifier + ", (" + start + "-" + end + "))";
	}
}
