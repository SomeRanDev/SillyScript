# Enums

Enums are collections of identifiers that can be used as types.

## Basic Syntax

An enum can be declared using the `enum` keyword:

```SillyScript
enum BreakfastFood:
	pancake;
	hash_brown;
	burger;
```

<br>

By default, an `enum` identifier will generate as its index.

doublecodeblock:
	The SillyScript definition call:
	```SillyScript
	hash_brown;
	```

	The equivalent JSON:
	```JSON
	[
		1
	]
	```

## Underlying Type

An `enum` can generate as other types. Simple add an ` -> TYPE` after the `enum` name to dictate what type it's converted to.

Currently only `string` and `int` are supported.

doublecodeblock:
	The SillyScript definition call:
	```SillyScript
	enum BreakfastFood -> string:
		pancake;
		hash_brown;
		burger;
 
	burger;
	```

	The equivalent JSON:
	```JSON
	[
		"burger"
	]
	```

## Argument

An `enum`'s name can be used as an argument.

doublecodeblock:
	The SillyScript definition call:
	```SillyScript
	enum BreakfastFood -> string:
		pancake;
		hash_brown;
		burger;
 
	def Eat(food: BreakfastFood) -> dict:
		action: "eat";
		food: food;
 
	Eat(pancake);
	Eat(burger);
	```

	The equivalent JSON:
	```JSON
	[
		{
			"action": "eat",
			"food": "pancake"
		},
		{
			"action": "eat",
			"food": "burger"
		}
	]
	```
