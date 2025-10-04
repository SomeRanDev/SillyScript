package sillyscript.filesystem;

using haxe.io.Path;
using sillyscript.extensions.ArrayExt;

/**
	Errors related to argument processing and file system IO.
**/
@:using(sillyscript.filesystem.Arguments.ArgumentsErrorExt)
enum ArgumentsError {
	NotEnoughArguments;
	CouldNotUnderstandFilePath;
	CouldNotReadInputFile(path: String);
	CouldNotWriteOutputFile(path: String);
}

/**
	Functions for `ArgumentsError`.
**/
class ArgumentsErrorExt {
	public static function message(self: ArgumentsError): String {
		return switch(self) {
			case NotEnoughArguments: "Invalid arguments, expected:\n\n\tSillyScript <input .silly file> <output file>";
			case CouldNotUnderstandFilePath: "Could not parse the text content of the arguments.";
			case CouldNotReadInputFile(path): "Could not read input file " + path;
			case CouldNotWriteOutputFile(path): "Could not write to output file " + path;
		}
	}
}

/**
	A value that is either `T` or `ArgumentsError`.
**/
enum ArgumentsResult<T> {
	Success(instance: T);
	Error(error: ArgumentsError);
}

/**
	A class containing the input command arguments passed to the program.
**/
@:structInit
class Arguments {
	var inputFile: File;
	var outputFile: File;

	public var dontColorErrors(default, null): Bool;

	/**
		Use this to construct an `Arguments` instance.
	**/
	public static function make(): ArgumentsResult<Arguments> {
		final args = #if (sys || hxnodejs) Sys.args() #else [] #end;
		if(args.length < 2) {
			return Error(NotEnoughArguments);
		}

		final inputFile = File.make(args.get(0));
		if(inputFile == null) return Error(CouldNotUnderstandFilePath);

		final outputFile = File.make(args.get(1));
		if(outputFile == null) return Error(CouldNotUnderstandFilePath);

		return Success({
			inputFile: inputFile,
			outputFile: outputFile,

			dontColorErrors: args.contains("--dont-color-errors"),
		});
	}

	public function getInputFilePath(): String {
		return inputFile.getPath();
	}

	public function getInputFilePathRelativeTo(path: String): String {
		final inputFilePath = getInputFilePath().normalize();
		final relativeTo = path.normalize();
		return StringTools.replace(inputFilePath, relativeTo.removeTrailingSlashes() + "/", "");
	}

	public function getInputContent(): ArgumentsResult<String> {
		return switch(inputFile.read()) {
			case Success(content): Success(content);
			case _: Error(CouldNotReadInputFile(inputFile.getPath()));
		}
	}

	public function writeOutputContent(content: String): ArgumentsResult<Bool> {
		return switch(outputFile.write(content)) {
			case Success: Success(true);
			case _: Error(CouldNotWriteOutputFile(outputFile.getPath()));
		}
	}
}
