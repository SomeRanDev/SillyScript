# Types

SillyScript is built on a handful of core-types.

## Booleans

The `bool` type can only store two options: `true` or `false`.

## Numbers

There are three number types: `int`, `uint`, and `float`. They are pretty self-explanatory and I'm too lazy to explain further.

## Strings

The `string` type is a string of characters. At the current moment you can only use double-quotes for strings.

## Null

Types can be assigned `null` to store nothing. When passing `null` to a typed entry, the type must be "nullable". A type can be made "nullable" by adding a question mark `?` to the end of it.

Non-nullable types can be passed the nullable ones, but the opposite is not true.

## List

A list of data entries. A mixed `list` is denoted with just `list`.

A list that only contains a single type can be denoted using `TYPE list`. For example: `int list`.

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
