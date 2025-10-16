# Definitions

Definitions can be used to simplify common patterns.

## Basic Syntax

A definition can be used to type specific data patterns.

```SillyScript
def Wait(duration: int) -> dict:
	type: 0;
	duration: duration;
```

<br>

Calling this definition places the resulting data where the call occurs.

doublecodeblock:
	The SillyScript definition call:
	```SillyScript
	def Wait(duration: int) -> dict:
		type: 0;
		duration: duration;
 
	Wait(123);
	```

	The equivalent JSON:
	```JSON
	[
		{
			"type": 0,
			"duration": 123
		}
	]
	```

## Arguments

Definition arguments are provided as a list of `NAME: TYPE` combinations. See [Types](types.html) for more information on types.

## Named Arguments

Arguments can also be passed by name. This allows only certain arguments to be used.

For example:

doublecodeblock:
	The SillyScript definition call:
	```SillyScript
	def Jump(
		height: float = 5.0,
		duration: int = 60
	) -> dict:
		type: 1;
		height: height;
		duration: duration;
 
	Jump(duration: 123);
	```

	The equivalent JSON:
	```JSON
	[
		{
			"type": 1,
			"height": 5.0,
			"duration": 123
		}
	]
	```
