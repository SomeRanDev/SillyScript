package sillyscript;

import haxe.macro.Expr;
import sillyscript.compiler.Parser.ParserError;
import sillyscript.Position.Positioned;

macro function returnIfError(self: ExprOf<Null<Positioned<ParserError>>>): Expr {
	return macro {
		final result = $self;
		if(result != null) {
			return Error([result]);
		}
	}
}
