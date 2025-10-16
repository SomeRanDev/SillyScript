package sillyscript.compiler.transpiler;

import sillyscript.compiler.executor.DataOutput;
import sillyscript.compiler.transpiler.Transpiler.TranspilerResult;
import sillyscript.Positioned;
using sillyscript.extensions.ArrayExt;

class JsonTranspiler extends Transpiler {
	public function transpile(): TranspilerResult {
		return transpileData(data);
	}

	function transpileData(data: Positioned<DataOutput>, tabs: String = ""): TranspilerResult {
		final jsonString = switch(data.value) {
			case Value(Null): "null";
			case Value(Bool(value)): value ? "true" : "false";
			case Value(Int(content)): content;
			case Value(Float(content)): {
				if(StringTools.startsWith(content, ".")) {
					"0" + content;
				} else if(StringTools.endsWith(content, ".")) {
					content + "0";
				} else {
					content;
				}
			}
			case Value(String(content)): {
				"\"" + content + "\"";
			}
			case List(items): {
				final buffer = new StringBuf();
				buffer.add("[\n" + tabs);
				final errors = [];
				var first = true;
				for(item in items) {
					if(first) {
						first = false;
					} else {
						buffer.add(",\n" + tabs);
					}
					switch(transpileData(item, tabs + "\t")) {
						case Success(content): {
							buffer.add("\t");
							buffer.add(content);
						}
						case Error(transpileErrors): errors.pushArray(transpileErrors);
					}
				}
				buffer.add("\n" + tabs + "]");
				buffer.toString();
			}
			case Dictionary(items): {
				final buffer = new StringBuf();
				buffer.add("{\n" + tabs);
				final errors = [];
				var first = true;
				for(item in items) {
					if(first) {
						first = false;
					} else {
						buffer.add(",\n" + tabs);
					}
					switch(transpileData(item.value.value, tabs + "\t")) {
						case Success(content): {
							buffer.add("\t");
							buffer.add("\"");
							buffer.add(item.value.key.value);
							buffer.add("\": ");
							buffer.add(content);
						}
						case Error(transpileErrors): {
							errors.pushArray(transpileErrors);
						}
					}
				}
				buffer.add("\n" + tabs + "}");
				buffer.toString();
			}
		}

		return Success(jsonString);
	}
}
