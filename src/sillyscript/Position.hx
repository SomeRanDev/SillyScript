package sillyscript;

enum PositionKind {
	SingleCharacter(index: Int);
	Range(start: Int, end: Int);
}

@:structInit
class Position {
	var file: String;
	var kind: PositionKind;

	public static function singleCharacter(file: String, index: Int): Position {
		return { file: file, kind: SingleCharacter(index) };
	}

	public static function range(file: String, start: Int, end: Int): Position {
		return { file: file, kind: Range(start, end) };
	}
}
