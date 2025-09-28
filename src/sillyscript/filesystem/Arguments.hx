package sillyscript.filesystem;

using sillyscript.Error;
using sillyscript.extensions.ArrayExt;

/**
	A class containing the input command arguments passed to the program.
**/
@:structInit
class Arguments {
	var inputFile: File;
	var outputFile: File;

	/**
		Use this to construct an `Arguments` instance.
	**/
	public static function make(): Null<Arguments> {
		final args = #if sys Sys.args() #else [] #end;
		if(args.length < 2) {
			NotEnoughArguments.print();
			return null;
		}

		final inputFile = File.make(args.get(0));
		if(inputFile == null) return null;

		final outputFile = File.make(args.get(1));
		if(outputFile == null) return null;

		return {
			inputFile: inputFile,
			outputFile: outputFile,
		};
	}

	public function getInputContent(): Null<String> {
		return switch(inputFile.read()) {
			case Success(content): content;
			case _: {
				CouldNotReadInputFile(inputFile.get_path()).print();
				null;
			}
		}
	}

	public function writeOutputContent(content: String): Bool {
		return switch(outputFile.write(content)) {
			case Success: true;
			case _: {
				CouldNotWriteOutputFile(outputFile.get_path()).print();
				false;
			}
		}
	}
}
