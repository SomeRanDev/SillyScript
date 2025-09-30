package sillyscript;

import haxe.macro.Compiler;
import sillyscript.filesystem.FileIdentifier;
using sillyscript.extensions.StringExt;

@:structInit
class Position {
	public var fileIdentifier(default, null): Int;
	public var start(default, null): Int;
	public var end(default, null): Int;

	public function merge(other: Position): Position {
		return {
			fileIdentifier: fileIdentifier,
			start: start < other.start ? start : other.start,
			end: end > other.end ? end : other.end,
		};
	}

	public function toString() {
		return fileIdentifier + " (" + start + " - " + end + ")";
	}
}

@:structInit
@:using(sillyscript.Position.PositionedExt)
class Positioned<T> {
	public var value(default, null): T;
	public var position(default, null): Position;

	public function toString() {
		return "At " + position.toString() + "\n(" + Std.string(value) + ")";
	}

	public function map<U>(callback: (T) -> U): Positioned<U> {
		return {
			value: callback(value),
			position: position
		}
	}
}

class PositionedExt {
	public static function renderErrorMessage(
		self: Positioned<CompileError>,
		fileIdentifier: FileIdentifier,
		message: String,
		decorated: Bool,
		surrondingLinesShown: Int = 1,
		fileLinkPath: Null<String> = null
	): Null<String> {
		final fileInfo = fileIdentifier.get(self.position.fileIdentifier);
		if(fileInfo == null) return null;

		final lines = fileInfo.content.split("\n");

		function findLineInfo(index: Int): { line: Int, col: Int } {
			var total = 0;
			for(i in 0...lines.length) {
				final line = lines[i];
				if(total + line.length + 1 > index) { // + 1 for "\n"
					return { line: i, col: index - total };
				}
				total += line.length + 1;
			}
			return {
				line: lines.length - 1,
				col: lines[lines.length - 1].length
			};
		}

		final startLineInfo = findLineInfo(self.position.start);
		final endLineInfo = findLineInfo(self.position.end - 1);
		final lineStart = Std.int(Math.max(0, startLineInfo.line - surrondingLinesShown));
		final lineEnd = Std.int(Math.min(lines.length, endLineInfo.line + surrondingLinesShown + 1));
		final lineNumberWidth = Std.string(lineEnd).length;

		final out = new StringBuf();

		if(decorated) {
			out.add("<light_red>");
		}
		out.add(self.value.errorKindString());
		if(decorated) {
			out.add("</>");
			out.add("<#FFF>");
		}
		out.add(": ");
		out.add(self.value.errorDescription());
		if(decorated) {
			out.add("</>");
		}
		out.add("\n");

		if(decorated) {
			out.add("<#61d6d6>");
		}
		out.add(" --> ");
		if(decorated) {
			out.add("</>");
		}
		out.add(fileInfo.name);
		out.add("\n");

		for(i in lineStart...lineEnd) {
			final number = Std.string(i + 1).rjust(lineNumberWidth, " ");
			final code = lines[i];
			if(decorated) {
				out.add("<#61d6d6>");
			}
			out.add(number);
			out.add(" | ");
			if(decorated) {
				out.add("</>");
			}
			out.add(code);
			if(decorated) {
			}
			out.add("\n");

			if(i < startLineInfo.line || i > endLineInfo.line) {
				continue;
			}

			final startX = (i == startLineInfo.line) ? startLineInfo.col : 0;
			final endX = (i == endLineInfo.line) ? endLineInfo.col : code.length;
			final endX = endX <= startX ? startX + 1 : endX;

			out.add(StringTools.rpad("", " ", lineNumberWidth + 3 + startX));
			if(decorated) {
				out.add("<light_red>");
			}
			out.add(StringTools.rpad("", "^", endX - startX));
			if(i == startLineInfo.line) {
				out.add(" " + self.value.errorHint());
			}
			if(decorated) {
				out.add("</>");
			}
			out.add("\n");
		}

		return out.toString();
	}
}

