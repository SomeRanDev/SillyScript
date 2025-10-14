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

			case ParserError(ParserNoMatch): {
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
			case ParserError(ExpectedExpression): {
				"Expected an expression.";
			}
			case ParserError(ExpectedType): {
				"Expected a type.";
			}
			case ParserError(ExpectedListOrDictionaryEntries): {
				"Expected a list or dictionary entry.";
			}
			case ParserError(UnexpectedEndOfTokens): {
				"Unexpected end of token feed.";
			}
			case ParserError(UnexpectedListEntryWhileParsingDictionary): {
				"List entry found while parsing dictionary entries.";
			}
			case ParserError(UnexpectedDictionaryEntryWhileParsingList): {
				"Dictionary entry found while parsing list entries.";
			}
			case ParserError(TypeCannotHaveSubtype(typeKind)): {
				typeKind + " cannot have a subtype.";
			}

			case TyperError(CompilerError(_)): {
				"This error should not be possible. Please report in the SillyScript repo!";
			}
			case TyperError(NothingWithName(name)): {
				"There is no declaration with this name.";
			}
			case TyperError(MissingArgument(def, argumentIndex)): {
				"Missing argument #" + argumentIndex + " of " + def.name + "(" + def.arguments[argumentIndex].value.name.value + ").";
			}
			case TyperError(WrongType): {
				"A value of this type cannot be passed to that type.";
			}
			case TyperError(WrongRole): {
				"Cannot pass type with different role.";
			}
			case TyperError(CannotPassNullableTypeToNonNullable): {
				"Cannot pass value of nullable type to non-nullable type.";
			}
			case TyperError(InconsistentTypeBetweenSyntaxTemplates): {
				"Inconsistent type between expression inputs of same name in different syntax templates.";
			}
			case TyperError(CannotCall(type)) if(type != null): {
				"Cannot call instances of type " + type.toString() + ".";
			}
			case TyperError(CannotCall(_)): {
				"Cannot call this expression of unknown type.";
			}
			case TyperError(AmbiguousCustomSyntaxCandidates(_)): {
				"Multiple custom syntax declarations can match this syntax.";
			}
			case TyperError(InvalidTypesForCustomSyntax(_)): {
				"The types used on this custom syntax do not match the input types it requires.";
			}
			case TyperError(InvalidTypesForMultipleCustomSyntaxCandidates(_)): {
				"There are multiple candidates for this custom syntax, but none match the types of the expressions provided.";
			}

			case ExecutorError(CannotExecuteDefIdentifier): {
				"Cannot convert uncalled def identifier to data.";
			}
			case ExecutorError(CannotCallExpression): {
				"Cannot call expression.";
			}
			case ExecutorError(UnidentifiedDefArgumentIdentifier): {
				"Unidentified def argument identifier.";
			}
			case ExecutorError(CannotExecuteEmptyDef): {
				"Cannot execute def that failed to compile.";
			}

			case TyperError(_) | TranspilerError(_): "placeholder";
		}
	}

	public static function errorHint(self: CompileError): String {
		return switch(self) {
			case LexerError(UnexpectedEndOfFile): {
				"the file ended unexpectedly here";
			}

			case ParserError(ParserNoMatch): {
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
			case ParserError(ExpectedExpression): {
				"this should be an expression";
			}
			case ParserError(ExpectedType): {
				"this should be a type";
			}
			case ParserError(ExpectedListOrDictionaryEntries): {
				"this should be a list/dictionary entry";
			}
			case ParserError(UnexpectedEndOfTokens): {
				"this should not be possible, please report";
			}
			case ParserError(UnexpectedListEntryWhileParsingDictionary): {
				"this should have label (MY_LABEL: ...)";
			}
			case ParserError(UnexpectedDictionaryEntryWhileParsingList): {
				"this shouldn't have a label";
			}
			case ParserError(TypeCannotHaveSubtype(_)): {
				"this should not have a type before it";
			}

			case TyperError(CompilerError(message)): {
				message;
			}
			case TyperError(NothingWithName(name)): {
				name + " is undefined";
			}
			case TyperError(MissingArgument(def, argumentIndex)): {
				"missing argument " + def.arguments[argumentIndex].value.name.value;
			}
			case TyperError(WrongType): {
				"these types are not the same";
			}
			case TyperError(WrongRole): {
				"these types have different roles";
			}
			case TyperError(CannotPassNullableTypeToNonNullable): {
				"this value might be null, but it is being passed to non-nullable type";
			}
			case TyperError(InconsistentTypeBetweenSyntaxTemplates): {
				"this must have the same type in all syntax templates";
			}
			case TyperError(CannotCall(type)) if(type != null): {
				"cannot call expression of type " + type.toString();
			}
			case TyperError(CannotCall(_)): {
				"cannot call this expression of unknown type";
			}
			case TyperError(AmbiguousCustomSyntaxCandidates(names)): {
				"this could be any of the following custom syntaxes: " + names.join(", ");
			}
			case TyperError(InvalidTypesForCustomSyntax(_)): {
				"invalid types for custom syntax";
			}
			case TyperError(InvalidTypesForMultipleCustomSyntaxCandidates(syntaxes)): {
				"invalid types for all of the following custom syntaxes: " + syntaxes.map(s -> s.name.value).join(", ");
			}

			case ExecutorError(CannotExecuteDefIdentifier): {
				"this should have () after it";
			}
			case ExecutorError(CannotCallExpression): {
				"cannot call this expression";
			}
			case ExecutorError(UnidentifiedDefArgumentIdentifier): {
				"this identifier is undefined, but expected to be an argument in a def declaration";
			}
			case ExecutorError(CannotExecuteEmptyDef): {
				"unfinished def";
			}

			case TranspilerError(_): "placeholder";
		}
	}
}
