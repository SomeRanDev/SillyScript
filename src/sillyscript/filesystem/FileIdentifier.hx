package sillyscript.filesystem;

typedef FileInfo = {
	name: String,
	content: String
};

class FileIdentifier {
	var files: Map<Int, FileInfo>;
	var maxId: Int;

	public function new() {
		files = [];
		maxId = 0;
	}

	public function registerFile(name: String, content: String): Int {
		final id = maxId++;
		files.set(id, { name: name, content: content });
		return id;
	}

	public function get(id: Int): Null<FileInfo> {
		return files.get(id);
	}
}