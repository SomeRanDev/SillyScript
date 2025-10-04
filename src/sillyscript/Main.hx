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
			Sys.stderr().writeString(error.message() + "\n");
			return;
		}
	}

	final input = switch(arguments.getInputContent()) {
		case Success(input): input;
		case Error(error): {
			Sys.stderr().writeString(error.message() + "\n");
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
				final errorString = compiler.getErrorString(e, !arguments.dontColorErrors);
				if(arguments.dontColorErrors) {
					Sys.stderr().writeString(errorString + "\n");
				} else {
					Console.printlnFormatted(errorString, Error);
				}
			}
			Sys.exit(1);
		}
	}
	#end
}
