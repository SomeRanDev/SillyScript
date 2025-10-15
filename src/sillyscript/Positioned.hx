package sillyscript;

import sillyscript.filesystem.FileIdentifier;
using sillyscript.extensions.StringExt;

enum DecorationKind {
	None;
	ConsoleHx;
	Html(errorColor: String, lineColor: String, highlightColor: String);
}

enum DecorationColorKind {
	Error;
	Line;
	Highlight;
}

@:structInit
@:using(sillyscript.Positioned.PositionedExt)
class Positioned<T> {
	public var value(default, null): T;
	public var position(default, null): Position;

	public function toString() {
		return "Positioned(at=" + position.toString() + ", " + Std.string(value) + ")";
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
		decoratedKind: DecorationKind,
		surroundingLinesShown: Int = 1,
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
		final lineStart = Std.int(Math.max(0, startLineInfo.line - surroundingLinesShown));
		final lineEnd = Std.int(Math.min(lines.length, endLineInfo.line + surroundingLinesShown + 1));
		final lineNumberWidth = Std.string(lineEnd).length;

		final out = new StringBuf();

		startColor(out, Error, decoratedKind);
		out.add(self.value.errorKindString());
		endColor(out, decoratedKind);
		startColor(out, Highlight, decoratedKind);
		out.add(": ");
		out.add(self.value.errorDescription());
		endColor(out, decoratedKind);
		out.add("\n");

		startColor(out, Line, decoratedKind);
		out.add(" --> ");
		endColor(out, decoratedKind);
		out.add(fileInfo.name);
		out.add("\n");

		for(i in lineStart...lineEnd) {
			final number = Std.string(i + 1).rjust(lineNumberWidth, " ");
			final code = lines[i];
			startColor(out, Line, decoratedKind);
			out.add(number);
			out.add(" | ");
			endColor(out, decoratedKind);
			out.add(code);
			out.add("\n");

			if(i < startLineInfo.line || i > endLineInfo.line) {
				continue;
			}

			final startX = (i == startLineInfo.line) ? startLineInfo.col : 0;
			final endX = (i == endLineInfo.line) ? endLineInfo.col : code.length;
			final endX = endX <= startX ? startX + 1 : endX;

			out.add(StringTools.rpad("", " ", lineNumberWidth + 3 + startX));
			startColor(out, Error, decoratedKind);
			out.add(StringTools.rpad("", "^", endX - startX));
			if(i == startLineInfo.line) {
				out.add(" " + self.value.errorHint());
			}
			endColor(out, decoratedKind);
			out.add("\n");
		}

		return out.toString();
	}

	static function startColor(buf: StringBuf, color: DecorationColorKind, kind: DecorationKind) {
		final content = switch(kind) {
			case ConsoleHx: {
				final color = switch(color) {
					case Error: "light_red";
					case Line: "#61d6d6";
					case Highlight: "#FFF";
				}
				"<" + color + ">";
			}
			case Html(ec, lc, hc): {
				final color = switch(color) {
					case Error: ec;
					case Line: lc;
					case Highlight: hc;
				}
				"<span style=\"color: " + color + "\">";
			}
			case _: "";
		}
		if(kind != None) {
			buf.add(content);
		}
	}

	static function endColor(buf: StringBuf, kind: DecorationKind) {
		final content = switch(kind) {
			case ConsoleHx: "</>";
			case Html(_, _, _): "</span>";
			case _: "";
		}
		if(kind != None) {
			buf.add(content);
		}
	}
}
