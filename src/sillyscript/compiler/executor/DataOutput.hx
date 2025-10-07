package sillyscript.compiler.executor;

import sillyscript.compiler.Value;
import sillyscript.Positioned;

enum DataOutput {
	Value(value: Value);
	List(items: Array<Positioned<DataOutput>>);
	Dictionary(items: Array<Positioned<{ key: Positioned<String>, value: Positioned<DataOutput> }>>);
}
