package sillyscript;

import haxe.macro.Expr;
import sillyscript.compiler.parser.ParserError;
import sillyscript.Positioned;

macro function returnIfError(self: ExprOf<Null<Positioned<ParserError>>>): Expr {
	return macro {
		final result = $self;
		if(result != null) {
			return Error([result]);
		}
	}
}

macro function returnIfErrorWith(self: ExprOf<Null<Positioned<ParserError>>>, errors: Expr): Expr {
	return macro {
		final result = $self;
		if(result != null) {
			return Error(errors.concat([result]));
		}
	}
}
