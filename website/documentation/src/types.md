# Types

SillyScript is built on a handful of core-types.

## Booleans

The `bool` type can only store two options: `true` or `false`.

doublecodeblock:
	SillyScript code:
	```SillyScript
	true;
	false;
	```

	The equivalent JSON:
	```JSON
	[
		true,
		false
	]
	```

## Numbers

There are two number types: `int` and `float`. `float`s can have numbers with decimal places, `int`s must be integers.

doublecodeblock:
	SillyScript code:
	```SillyScript
	1;
	0.5;
	```

	The equivalent JSON:
	```JSON
	[
		1,
		0.5
	]
	```

## Strings

The `string` type is a string of characters. At the current moment you can only use double-quotes for strings.

doublecodeblock:
	SillyScript code:
	```SillyScript
	"Hello world";
	```

	The equivalent JSON:
	```JSON
	[
		"Hello world"
	]
	```

## Null

Types can be assigned `null` to store nothing. When passing `null` to a typed entry, the type must be "nullable". A type can be made "nullable" by adding a question mark `?` to the end of it.

Non-nullable types can be passed the nullable ones, but the opposite is not true.

doublecodeblock:
	SillyScript code:
	```SillyScript
	null;
 
	def MaybeGiveInt(a: int?) -> list:
		a;
 
	MaybeGiveInt(12);
	MaybeGiveInt(null);
	```

	The equivalent JSON:
	```JSON
	[
		null,
		[ 12 ],
		[ null ]
	]
	```

## List

A list of data entries. A mixed `list` is denoted with just `list`.

A list that only contains a single type can be denoted using `TYPE list` (for example: `int list`).

doublecodeblock:
	SillyScript code:
	```SillyScript
	def OneTwoThree() -> int list:
		1; 2; 3;
 
	def TakeList(list: int list) -> dict:
		data: list;
 
	TakeList(OneTwoThree());
	```

	The equivalent JSON:
	```JSON
	[
		{
			"data": [1, 2, 3]
		}
	]
	```

## Dictionary

An unordered list of data entries with a unique identifier for each entry. A mixed `dict` is denoted with just `dict`.

A dictionary that only contains a single type can be denoted using `TYPE dict`. For example: `string dict`.

## Roles

A "role" can be given to a type as a piece of metadata. This is done using an exclamation point `!`.

```SillyScript
def Something(input: dict!funny) -> dict!sad:
	count: input.number
```

A type with a role can only be passed to another type with the same role identifier.

```SillyScript
# Error: dict!sad cannot be passed to dict!funny.
Something(Something({ number: 32 }));
```
