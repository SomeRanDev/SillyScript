package sillyscript;

import sillyscript.Position.PositionKind;
import sillyscript.Error.ErrorKind;
import sillyscript.compiler.Lexer;

enum CompileResult {
	Success(content: String);
	Error(errors: Array<{ error: ErrorKind, position: PositionKind }>);
}

/**
	The class that manages the main SillyScript compilation behavior.
**/
class SillyScript {
	/**
		Constructor.
	**/
	public function new() {
	}

	/**
		The function that takes a complete SillyScript file as `input` and returns the generated
		output data.
	**/
	public function compile(input: String, filePath: Null<String> = null): CompileResult {
		final lexer = new Lexer(input, filePath);
		final tokens = switch(lexer.lexify()) {
			case Success(tokens): tokens;
			case Error(errors): return Error(errors);
		}

		trace(tokens);

		return Success("");
	}
}
