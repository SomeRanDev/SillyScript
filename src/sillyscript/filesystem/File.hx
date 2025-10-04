package sillyscript.filesystem;

#if (sys || hxnodejs)
import sys.FileSystem;
import sys.io.File as SysFile;
#end

/**
	Used for the result of `File.read`.
**/
enum FileReadResult {
	Success(content: String);
	DoesNotExist;
	UnknownError;
}

/**
	Used for the result of `File.write`.
**/
enum FileWriteResult {
	Success;
	DoesNotExist;
	UnknownError;
}

/**
	Represents a file.
**/
class File {
	var path: String;
	var exists: Bool;

	/**
		An alternative constructor that can take a nullable String.
		Returns `null` if `null` is given.
	**/
	public static function make(maybePath: Null<String>): Null<File> {
		if(maybePath == null) return null;
		return new File(maybePath);
	}

	/**
		Constructor. A relative or absolute path may be provided to any file.
	**/
	public function new(filePath: String) {
		#if (sys || hxnodejs)
		path = haxe.io.Path.isAbsolute(filePath) ? filePath : sys.FileSystem.absolutePath(filePath);
		exists = FileSystem.exists(path);
		#else
		path = "";
		exists = false;
		#end
	}

	/**
		Returns absolute path this file represents.
	**/
	public function getPath(): String {
		return path;
	}

	/**
		Reads the text content of this file.
	**/
	public function read(): FileReadResult {
		if(!exists) {
			return DoesNotExist;
		}
		return try {
			#if (sys || hxnodejs)
			Success(SysFile.getContent(path));
			#else
			Success("");
			#end
		} catch(_) {
			UnknownError;
		}
	}

	/**
		Writes `content` to this file's `path`.
	**/
	public function write(content: String): FileWriteResult {
		return try {
			#if (sys || hxnodejs)
			SysFile.saveContent(path, content);
			#end
			Success;
		} catch(_) {
			UnknownError;
		}
	}
}
