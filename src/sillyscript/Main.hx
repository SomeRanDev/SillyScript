package sillyscript;

import sillyscript.filesystem.Arguments;

/**
	The main function for the compiler executable.
**/
function main() {
	#if (sys || hxnodejs)
	final arguments = switch(Arguments.make()) {
		case Success(arguments): arguments;
		case Error(error): {
			Sys.println(error.message());
			return;
		}
	}

	final input = switch(arguments.getInputContent()) {
		case Success(input): input;
		case Error(error): {
			Sys.println(error.message());
			return;
		}
	}
	
	final compiler = new SillyScript();
	switch(compiler.compile(
		input,
		arguments.getInputFilePathRelativeTo(Sys.getCwd()),
		"file:///" + arguments.getInputFilePath()
	)) {
		case Success(content): {
			arguments.writeOutputContent(content);
		}
		case Error(errors): {
			for(e in errors) {
				Console.printlnFormatted(compiler.getErrorString(e, true));
			}
		}
	}
	#end
}
