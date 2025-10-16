# Syntax

The fundamentals of this language make it seem so useless and... silly. Just bear with it, it will make sense eventually.

## Top-Level Syntax

All SillyScript code represents data. It can represent a list or dictionary.

While SillyScript can export to multiple data formats, JSON is the main one used in this documentation to represent how the structure of the language works.

### List

The contents on the left side is an entirely valid SillyScript file. 

doublecodeblock:
	This is an entire valid SillyScript file:
	```SillyScript
	1;
	"This is a string";
	false;
	```


	It is the equivalent of this JSON:
	```JSON
	[1, "This is a string", false]
	```

### Dictionary

doublecodeblock:
	This is ALSO an entire valid SillyScript file:
	```SillyScript
	my_number: 1;
	MyString: "This is a string";
	myBool: false;
	```

	It is the equivalent of this JSON:
	```JSON
	{
		"my_number": 1,
		"MyString": "This is a string",
		"myBool": false
	}
	```

### Combination

SillyScript will automatically figure out if the file should be a `List` type of `Dictionary` type. These two types cannot be combined.

This is NOT a valid SillyScript file. The string must be labeled, or the labels must be removed from the number and boolean.
```SillyScript
my_number: 1;
"This is a string";
myBool: false;
```

Lists and dictionaries can be mixed by adding them as sub-elements to each other using the proper syntax.

#### List

Use the blank colon syntax to create a new scope for a list. 
```SillyScript
:
	1;
	2;
	3;
```

#### Dictionary

Use the blank colon syntax to create a new scope for a dictionary.
```SillyScript
:
	key1: 1;
	something: 2;
	bla: 3;
```

#### Combination

Here is an example of combining list and dictionaries and its equivalent in JSON:

doublecodeblock:
	A complicated structure in SillyScript.
	```SillyScript
	myList:
		1;
		"My String";
		:
			3;
			2;
			1;
		:
			thisIsDict: 321;
	myString: "Another String";
	```

	What it represents in JSON.
	```JSON
	{
		"myList": [
			1,
			"My String",
			[3, 2, 1],
			{ "thisIsDict": 321 }
		],
		"myString": "Another String"
	}
	```
