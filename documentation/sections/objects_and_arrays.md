## Objects and Arrays

The CoffeeScript literals for objects and arrays look very similar to their JavaScript cousins. When each property is listed on its own line, the commas are optional. Objects may be created using indentation instead of explicit braces, similar to [YAML](http://yaml.org).

```
codeFor('objects_and_arrays', 'song.join(" … ")')
```

In JavaScript, you can’t use reserved words, like `class`, as properties of an object, without quoting them as strings. CoffeeScript notices reserved words used as keys in objects and quotes them for you, so you don’t have to worry about it (say, when using jQuery).

```
codeFor('objects_reserved')
```

CoffeeScript has a shortcut for creating objects when you want the key to be set with a variable of the same name.

```
codeFor('objects_shorthand')
```
