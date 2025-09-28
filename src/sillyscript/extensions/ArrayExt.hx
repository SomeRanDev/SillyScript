package sillyscript.extensions;

class ArrayExt {
	/**
		Since Haxe sucks, `array[x]` doesn't get typed as `Null<T>`.

		This function should be used over `array[x]` to ensure null-safety functions.
	**/
	public static inline function get<T>(self: Array<T>, index: Int): Null<T> {
		return if(index >= 0 || index < self.length) {
			self[index];
		} else {
			null;
		}
	}
}
