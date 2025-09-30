package sillyscript.extensions;

class StringExt {
	/**
		Filters characters from `self`. Only characters that return `true` from `filterCallback`
		will be included in the newly generated returning `String`.
	**/
	public static inline function filter(self: String, filterCallback: (Int) -> Bool): String {
		final sb = new StringBuf();
		for(i in 0...self.length) {
			final charCode = self.charCodeAt(i);
			if(charCode != null && filterCallback(charCode)) {
				sb.addChar(charCode);
			}
		}
		return sb.toString();
	}

	/**
		Right justify.
	**/
	public static inline function rjust(s: String, width: Int, pad: String): String {
		while(s.length < width) {
			s = pad + s;
		}
		return s;
	}
}
