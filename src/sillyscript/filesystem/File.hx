package sillyscript.filesystem;

import sys.FileSystem;
import sys.io.File as SysFile;

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
	public function new(path: String) {
		this.path = haxe.io.Path.isAbsolute(path) ? path : sys.FileSystem.absolutePath(path);
		exists = FileSystem.exists(path);
	}

	/**
		Returns absolute path this file represents.
	**/
	public function get_path(): String {
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
			Success(SysFile.getContent(path));
		} catch(_) {
			UnknownError;
		}
	}

	/**
		Writes `content` to this file's `path`.
	**/
	public function write(content: String): FileWriteResult {
		return try {
			SysFile.saveContent(path, content);
			Success;
		} catch(_) {
			UnknownError;
		}
	}
}
