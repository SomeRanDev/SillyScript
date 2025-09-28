package sillyscript;

/**
	Every possible error SillyScript can generate.
**/
enum ErrorKind {
	NotEnoughArguments;
	CouldNotReadInputFile(path: String);
	CouldNotWriteOutputFile(path: String);

	UnexpectedEndOfFile;
}

/**
	Helper functions that should be called as extension functions on `ErrorKind`.
**/
class Error {
	static var errorStack: Array<{ error: ErrorKind, position: Position }> = [];

	static function message(self: ErrorKind): String {
		return switch(self) {
			case NotEnoughArguments: "Invalid arguments, expected:\n\n\tSillyScript <input .silly file> <output file>";
			case CouldNotReadInputFile(path): "Could not read input file " + path;
			case CouldNotWriteOutputFile(path): "Could not write to output file " + path;
			case UnexpectedEndOfFile: "Unexpected end of file.";
		}
	}

	public static function print(self: ErrorKind) {
		Sys.println(message(self));
	}

	public static function push(self: ErrorKind, position: Position) {
		errorStack.push({
			error: self,
			position: position
		});
	}
}
