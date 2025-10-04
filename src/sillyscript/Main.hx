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
			Console.printlnFormatted(error.message(), Error);
			return;
		}
	}

	final input = switch(arguments.getInputContent()) {
		case Success(input): input;
		case Error(error): {
			Console.printlnFormatted(error.message(), Error);
			return;
		}
	}
	
	final compiler = new SillyScript();
	switch(compiler.compile(
		input,
		arguments.getInputFilePathRelativeTo(Sys.getCwd())
	)) {
		case Success(content): {
			arguments.writeOutputContent(content);
		}
		case Error(errors): {
			for(e in errors) {
				Console.printlnFormatted(compiler.getErrorString(e, true), Error);
			}
			Sys.exit(1);
		}
	}
	#end
}
