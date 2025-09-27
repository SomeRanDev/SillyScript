# Functions

I'm not sure if I'm going to keep calling these "functions", but for now they get to be called that.

## Basic Syntax

A function can be used to type specific data patterns.

```SillyScript
def Wait(duration: int = 60) -> dict:
	type: 0;
	duration: duration;
```

Calling this function places the resulting data where the call occurs.

doublecodeblock:
	The SillyScript function call:
	```SillyScript
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

## Named Parameters

Parameters can also be passed by name. This allows only certain arguments to be used.

A SillyScript function like this...
```SillyScript
def Jump(height: float = 5.0, duration: int = 60) -> dict:
	type: 1;
	height: height;
	duration: duration;
```

... can be called like this:

doublecodeblock:
	The SillyScript function call:
	```SillyScript
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
