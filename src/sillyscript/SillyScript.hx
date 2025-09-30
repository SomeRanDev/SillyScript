package sillyscript;

import sillyscript.filesystem.FileIdentifier;
import sillyscript.Position.Positioned;
import sillyscript.compiler.Lexer.LexerError;
import sillyscript.compiler.Context;
import sillyscript.compiler.Lexer;
import sillyscript.compiler.Parser;

/**
	The result returned from `SillyScript.compile`.
**/
enum CompileResult {
	Success(content: String);
	Error(errors: Array<Positioned<CompileError>>);
}

/**
	The class that manages the main SillyScript compilation behavior.
**/
class SillyScript {
	var fileIdentifier: FileIdentifier;

	/**
		Constructor.
	**/
	public function new() {
		fileIdentifier = new FileIdentifier();
	}

	/**
		The function that takes a complete SillyScript file as `input` and returns the generated
		output data.

		`fileIdentifier` is a unique `String` used to identify the file when generating errors.
	**/
	public function compile(input: String, fileIdentifierString: String, fileLink: Null<String> = null): CompileResult {
		final fileId = fileIdentifier.registerFile(fileIdentifierString, input, fileLink);

		// Lexer
		final lexer = new Lexer(input, fileId);
		final tokens = switch(lexer.lexify()) {
			case Success(tokens): tokens;
			case Error(errors): return Error(errors.map(e -> ({
				value: LexerError(e.value),
				position: e.position
			} : Positioned<CompileError>)));
		}

		// Parser
		final context = new Context(fileId);
		final parser = new Parser(tokens, context);
		switch(parser.parse()) {
			case Success(result): trace(result);
			case NoMatch: trace("Nothing found");
			case Error(errors): return Error(errors.map(e -> ({
				value: ParserError(e.value),
				position: e.position
			} : Positioned<CompileError>)));
		}

		return Success("");
	}

	/**
		Generates the pretty-printed error message.

		If `decorated` is `true`, it will also be beautified with colors and format syntax
		compatible with [Console.hx](https://github.com/haxiomic/console.hx).
	**/
	public function getErrorString(error: Positioned<CompileError>, decorated: Bool) {
		return error.renderErrorMessage(fileIdentifier, Std.string(error.value), decorated);
	}
}
