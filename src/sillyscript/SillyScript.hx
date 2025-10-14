package sillyscript;

import sillyscript.compiler.Context;
import sillyscript.compiler.executor.Executor;
import sillyscript.compiler.lexer.Lexer;
import sillyscript.compiler.parser.Parser;
import sillyscript.compiler.transpiler.JsonTranspiler;
import sillyscript.compiler.typer.Typer;
import sillyscript.filesystem.FileIdentifier;
import sillyscript.Positioned;
import sillyscript.Positioned.DecorationKind;

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
#if js
@:expose
#end
@:keep
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
	public function compile(input: String, fileIdentifierString: String): CompileResult {
		final fileId = fileIdentifier.registerFile(fileIdentifierString, input);
		final context = new Context(fileId);

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
		final parser = new Parser(tokens, context);
		final untypedAst = switch(parser.parse()) {
			case Success(result): result;
			case NoMatch: {
				return Error([{
					value: ParserError(ParserNoMatch),
					position: { fileIdentifier: fileId, start: -1, end: -1 }
				}]);
			}
			case Error(errors): {
				return Error(errors.map(e -> ({
					value: ParserError(e.value),
					position: e.position
				} : Positioned<CompileError>)));
			}
		}

		// Typer
		final typer = new Typer(untypedAst, context);
		final typedAst = switch(typer.type()) {
			case Success(typedAst): typedAst;
			case Error(errors): return Error(errors.map(e -> ({
				value: TyperError(e.value),
				position: e.position
			} : Positioned<CompileError>)));
		}

		// Executor
		final executor = new Executor(typedAst, context);
		final data = switch(executor.execute()) {
			case Success(data): data;
			case Error(errors): return Error(errors.map(e -> ({
				value: ExecutorError(e.value),
				position: e.position
			} : Positioned<CompileError>)));
		}

		// Transpiler
		final transpiler = new JsonTranspiler(data, context);
		final output = switch(transpiler.transpile()) {
			case Success(output): output;
			case Error(errors): return Error(errors.map(e -> ({
				value: TranspilerError(e.value),
				position: e.position
			} : Positioned<CompileError>)));
		}

		return Success(output);
	}

	/**
		Generates the pretty-printed error message.

		If `decorated` is `true`, it will also be beautified with colors and format syntax
		compatible with [Console.hx](https://github.com/haxiomic/console.hx).
	**/
	public function getErrorString(error: Positioned<CompileError>, decorated: DecorationKind) {
		return error.renderErrorMessage(fileIdentifier, Std.string(error.value), decorated);
	}
}
