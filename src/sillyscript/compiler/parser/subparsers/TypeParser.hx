package sillyscript.compiler.parser.subparsers;

import haxe.ds.Either;
import sillyscript.compiler.typer.SillyTypeKind;
import sillyscript.compiler.parser.ParserResult.ParseResult;
import sillyscript.compiler.typer.SillyType;
import sillyscript.Positioned;
using sillyscript.extensions.ArrayExt;

/**
	Handles the parsing of types.
**/
@:access(sillyscript.compiler.parser.Parser)
class TypeParser {
	/**
		Parses an entire SillyScript type.
	**/
	public static function parseType(parser: Parser): ParseResult<Positioned<AmbiguousType>> {
		final types: Array<Positioned<AmbiguousType>> = [];
		while(true) {
			switch(parseTypeNameAndSuffixes(parser)) {
				case Success(result): types.push(result);
				case NoMatch: break;
				case Error(errors): return Error(errors);
			}
		}

		if(types.length == 0) {
			return NoMatch;
		}

		final errors: Array<Positioned<ParserError>> = [];

		while(types.length > 1) {
			final first = types.get(0);
			final second = types.get(1);
			if(first == null || second == null) continue;

			var newType = second.value.withSubtype(second.position, first);
			if(newType == null) {
				newType = second.value;

				switch(second.value) {
					case Known(type): {
						errors.push({
							value: TypeCannotHaveSubtype(type.kind),
							position: second.position
						});
					}
					case _: {
						// `withSubtype` can only return `null` when `self` is `Known`.
						// Therefore this will never execute.
						errors.push({
							value: CompilerError("withSubtype returned `null` on unknown type."),
							position: second.position
						});
					}
				}
			}

			final newPosition = first.position.merge(second.position);
			types.splice(0, 2);
			types.unshift({
				value: newType,
				position: newPosition
			});
		}

		if(errors.length > 0) {
			return Error(errors);
		}

		final finalType = types.get(0);
		return if(finalType != null) {
			Success(finalType);
		} else {
			NoMatch;
		}
	}

	/**
		Parses the type name, its role, and whether it's nullable (has `?` at end).
	**/
	static function parseTypeNameAndSuffixes(parser: Parser): ParseResult<Positioned<AmbiguousType>> {
		final start = parser.currentIndex;

		final kind = switch(parseTypeName(parser)) {
			case Success(kind): kind;
			case NoMatch: return NoMatch;
			case Error(errors): return Error(errors);
		}

		var role: Null<String> = null;
		switch(parser.peek()) {
			case ExclamationPoint: {
				switch(parser.peek(1)) {
					case Identifier(content): {
						parser.expectOrFatal(ExclamationPoint);
						parser.expectOrFatal(Identifier(content));
						role = content;
					}
					case _:
				}
			}
			case _:
		}

		final nullable = switch(parser.peek()) {
			case QuestionMark: {
				parser.expectOrFatal(QuestionMark);
				true;
			}
			case _: false;
		}

		return Success({
			value: switch(kind.value) {
				case Left(knownKind): Known({
					kind: knownKind,
					nullable: nullable,
					role: role,
				});
				case Right(unknownName): Unknown(unknownName, {
					kind: Any,
					nullable: nullable,
					role: role,
				});
			},
			position: parser.makePositionFrom(start, false)
		});
	}

 	static function parseTypeName(parser: Parser): ParseResult<Positioned<Either<SillyTypeKind, Positioned<String>>>> {
		final peekToken = parser.peekWithPosition();
		if(peekToken == null) return NoMatch;

		final identifier = switch(peekToken.value) {
			case Identifier(identifier): identifier;
			case _: return NoMatch;
		}

		final result = switch(identifier) {
			case "any": Left(Any);
			case "bool": Left(Bool);
			case "int": Left(Int);
			case "float": Left(Float);
			case "string": Left(String);
			case "list": Left(List(SillyType.ANY));
			case "dict": Left(Dictionary(SillyType.ANY));
			case identifier: Right(({ value: identifier, position: peekToken.position } : Positioned<String>));
		}

		parser.advance();

		return Success({
			value: result,
			position: peekToken.position
		});
	}
}