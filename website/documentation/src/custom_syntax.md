# Custom Syntax

SillyScript is about being silly; what's more silly than programming your programming language in your programming language? How certain statements should be generated for each project may be different, so it's up to the user to describe which statements are supported and how they are generated.

The `syntax` keyword can be used to create custom syntax. The structure of a custom syntax declaration looks like this:

```SillyScript
syntax NAME:
	pattern:
		PATTERN
```

<table>
  <tr>
    <th>Input</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>NAME</code></td>
    <td>A globally unique name for your syntax declaration.</td>
  </tr>
  <tr>
    <td><code>PATTERN</code></td>
    <td>The syntax template this declaration adds.</td>
  </tr>
</table>
<br>

Here is an example of a very basic custom syntax.

doublecodeblock:
	The SillyScript custom syntax:
	```SillyScript
	syntax WobblyLine:
		pattern:
			~~~
 
	~~~;
	```

	The equivalent JSON:
	```JSON
	[
		{ }
	]
	```

## Expression Inputs

The above syntax doesn't take any expression inputs, so it simply generates an empty object.

To accept expressions within the custom syntax, an argument surrounded by triangle brackets may be used:

doublecodeblock:
	The SillyScript custom syntax:
	```SillyScript
	syntax Shout:
		pattern:
			<words: string>!!!
 
	"Hello"!!!;
	```

	The equivalent JSON:
	```JSON
	[
		{ "words": "Hello" }
	]
	```

## Multiple Patterns

A single custom-syntax declaration may contain multiple patterns. Each pattern may have different expression inputs, but any expression inputs with the same names MUST also have the same types.

doublecodeblock:
	The SillyScript custom syntax:
	```SillyScript
	syntax Action:
		pattern:
			<name: string> ate <count: int>;
		
		pattern:
			<name: string> ate just one.
 
	Horse ate 3;
	Horse ate just one;
	```

	The equivalent JSON:
	```JSON
	[
		{ "name": "Horse", "count": 3 },
		{ "name": "Horse", "count": null }
	]
	```


## If Example

Let's try a more complicated example: an `if` statement.

```SillyScript
syntax If:
	pattern -> dict!action:
		if <condition: dict!condition>:
			<contents: dict!action list>
```

This could be used in this SillyScript like so:

doublecodeblock:
	```SillyScript
	def Has(name: string, value: int) -> dict!condition:
		name: name;
		value: value;
		
	def DoThing(action_name: string) -> dict!action:
		action: action_name;
		
	DoThing("Hop");
	if Has("something", 123):
		DoThing("Skip");
		DoThing("Jump");
	```

	```JSON
	[
		{ "action": "Hop" },
		{
			"type": 2,
			"condition": {
				"name": "something",
				"value": 123
			},
			"contents": [
				{ "action": "Skip" },
				{ "action": "Jump" }
			]
		}
	]
	```

## Pattern Type

To specify the type a pattern returns using ` -> TYPE`. This can be helpful for assigning roles to `dict`s returned by patterns.

This can be used to simulate custom operators:

```SillyScript
syntax NumEquality:
	pattern -> dict!condition:
		<left_number: dict!num> == <right_number: dict!num>
```

<br>

Borrowing from the `if` syntax code above, one can do:

doublecodeblock:
	```SillyScript
	def Number(num: int) -> dict!num:
		type: 0;
		num: num;
 
	def GetJumpCount() -> dict!num:
		type: 1;
 
	if GetJumpCount() == Number(3):
		DoThing("TripleJump");
	```

	```JSON
	[
		{
			"type": 2,
			"condition": {
				"left_number": {
					"type": 1
				},
				"right_number": {
					"type": 0,
					"num": 3
				}
			},
			"contents": [
				{ "action": "TripleJump" }
			]
		}
	]
	```


## Else Example

Let's say we want to allow for an "else" case in our "if" syntax. Let's create a new syntax declaration. We need to add `internal: true` so this syntax isn't available for use with normal code.

```SillyScript
syntax Else:
	pattern:
		else:
			<contents: dict!action list>
```

Now we can add an optional "else" case in our "if" syntax. The `?` after the "else_contents" identifier means this syntax is optional. The "if" still works even if there isn't an "else".

```SillyScript
syntax If:
	pattern:
		if <condition: dict!condition>:
			<contents: dict!action list>
		<else_contents?: syntax!Else>
```
