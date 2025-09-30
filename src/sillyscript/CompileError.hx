package sillyscript;

import sillyscript.compiler.executor.ExecutorError;
import sillyscript.compiler.lexer.LexerError;
import sillyscript.compiler.parser.ParserError;
import sillyscript.compiler.transpiler.TranspilerError;
import sillyscript.compiler.typer.TyperError;

@:using(sillyscript.CompileError.CompileErrorExt)
enum CompileError {
	LexerError(error: LexerError);
	ParserError(error: ParserError);
	TyperError(error: TyperError);
	ExecutorError(error: ExecutorError);
	TranspilerError(error: TranspilerError);
}

/**
	Functions for `CompileError`.
**/
class CompileErrorExt {
	public static function errorKindString(self: CompileError): String {
		return switch(self) {
			case LexerError(_): "Lexer Error";
			case ParserError(_): "Parser Error";
			case TyperError(_): "Typing Error";
			case ExecutorError(_): "Execution Error";
			case TranspilerError(_): "Transpiler Error";
		}
	}

	public static function errorDescription(self: CompileError): String {
		return switch(self) {
			case LexerError(UnexpectedEndOfFile): {
				"Unexpected end of file.";
			}

			case ParserError(NoMatch): {
				"Unexpected content encountered that does not match SillyScript syntax.";
			}
			case ParserError(Expected(token)) | ParserError(ExpectedMultiple([token])): {
				"Expected " + token;
			}
			case ParserError(ExpectedMultiple([])): {
				"Expected unknown token. This is a SillyScript compiler bug, please report.";
			}
			case ParserError(ExpectedMultiple([first, second])): {
				"Expected either " + first + " or " + second;
			}
			case ParserError(ExpectedMultiple(tokens)): {
				"Expected one of the following tokens: " + tokens;
			}
			case ParserError(ExpectedValue): {
				"Expected a value.";
			}
			case ParserError(ExpectedListOrDictionaryEntries): {
				"Expected a list or dictionary entry.";
			}
			case ParserError(UnexpectedListEntryWhileParsingDictionary): {
				"List entry found while parsing dictionary entries.";
			}
			case ParserError(UnexpectedDictionaryEntryWhileParsingList): {
				"Dictionary entry found while parsing list entries.";
			}

			case TyperError(_) | ExecutorError(_) | TranspilerError(_): "placeholder";
		}
	}

	public static function errorHint(self: CompileError): String {
		return switch(self) {
			case LexerError(UnexpectedEndOfFile): {
				"the file ended unexpectedly here";
			}

			case ParserError(NoMatch): {
				"unexpected content encountered";
			}
			case ParserError(Expected(token)) | ParserError(ExpectedMultiple([token])): {
				"expected a " + token + " here";
			}
			case ParserError(ExpectedMultiple([])): {
				"???";
			}
			case ParserError(ExpectedMultiple([first, second])): {
				"expected either " + first + " or " + second + " here";
			}
			case ParserError(ExpectedMultiple(tokens)): {
				"expected only " + tokens + " here";
			}
			case ParserError(ExpectedValue): {
				"this should be a value";
			}
			case ParserError(ExpectedListOrDictionaryEntries): {
				"this should be a list/dictionary entry";
			}
			case ParserError(UnexpectedListEntryWhileParsingDictionary): {
				"this should have label (MYLABEL: ...)";
			}
			case ParserError(UnexpectedDictionaryEntryWhileParsingList): {
				"this shouldn't have a label";
			}

			case TyperError(_) | ExecutorError(_) | TranspilerError(_): "placeholder";
		}
	}
}
