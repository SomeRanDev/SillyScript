package sillyscript.extensions;

/**
	This is an array wrapper that simply supports adding and removing from the end of the array.
	Used to document instances where the array is treated as a stack.
**/
@:forward(length)
abstract Stack<T>(Array<T>) from Array<T> {
	/**
		Add an element to the top of the stack.
	**/
	public inline function pushTop(item: T) {
		this.push(item);
	}

	/**
		Remove an element from the top of the stack and return it.
		Returns `null` if empty.
	**/
	public inline function popTop(): Null<T> {
		return this.pop();
	}

	/**
		Returns the most recently added element to the stack.
		Returns `null` if empty.
	**/
	public inline function last(): Null<T> {
		return this[this.length - 1];
	}

	/**
		Iterates from the most recently added element to the first element added.
	**/
	public function topToBottomIterator(): Iterator<T> {
		var index = 0;
		return {
			hasNext: () -> index < this.length,
			next: () -> {
				final result = this[this.length - index - 1];
				index++;
				return result;
			}
		}
	}

	/**
		The opposite of `topToBottomIterator`: iterates from the first element added to the most
		recently added one.
	**/
	public inline function bottomToTopIterator(): Iterator<T> {
		return this.iterator();
	}
}
