package sillyscript;

import sillyscript.filesystem.Arguments;

/**
	The main function for the compiler executable.
**/
function main() {
	#if sys
	final args = Arguments.make();
	if(args == null) return;

	final input = args.getInputContent();
	if(input == null) return;

	final compiler = new SillyScript();
	switch(compiler.compile(input)) {
		case Success(content): {
			args.writeOutputContent(content);
		}
		case Error(errors): {
			Sys.println(errors);
		}
	}
	#end
}
