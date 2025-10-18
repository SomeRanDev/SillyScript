package sillyscript;

import sillyscript.filesystem.Arguments;
import sillyscript.Positioned.DecorationKind;

/**
	The main function for the compiler executable.
**/
function main() {
	#if (js && nodejs.module)
	nodeJsModuleMain();
	#elseif (sys || (hxnodejs && nodejs.execute))
	commandLineMain();
	#end
}

#if (js && nodejs.module)
/**
	Exports `sillyscript.SillyScript` class when compiled as a NodeJS module.
**/
function nodeJsModuleMain() {
	untyped __js__("module.exports = { SillyScript: $hx_exports[\"SillyScript\"] };");
}
#end

#if (sys || (hxnodejs && nodejs.execute))
/**
	Runs SillyScript assuming it's called from the command-line.
**/
function commandLineMain() {
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
				final decorationKind = arguments.dontColorErrors ? None : ConsoleHx;
				final errorString = compiler.getErrorString(e, decorationKind);
				if(arguments.dontColorErrors) {
					Sys.stderr().writeString(errorString + "\n");
				} else {
					Console.printlnFormatted(errorString, Error);
				}
			}
			Sys.exit(1);
		}
	}
}
#end
