## Loops and Comprehensions

Most of the loops you’ll write in CoffeeScript will be **comprehensions** over arrays, objects, and ranges. Comprehensions replace (and compile into) `for` loops, with optional guard clauses and the value of the current array index. Unlike for loops, array comprehensions are expressions, and can be returned and assigned.

```
codeFor('array_comprehensions')
```

Comprehensions should be able to handle most places where you otherwise would use a loop, `each`/`forEach`, `map`, or `select`/`filter`, for example:<br>
`shortNames = (name for name in list when name.length < 5)`<br>
If you know the start and end of your loop, or would like to step through in fixed-size increments, you can use a range to specify the start and end of your comprehension.

```
codeFor('range_comprehensions', 'countdown')
```

Note how because we are assigning the value of the comprehensions to a variable in the example above, CoffeeScript is collecting the result of each iteration into an array. Sometimes functions end with loops that are intended to run only for their side-effects. Be careful that you’re not accidentally returning the results of the comprehension in these cases, by adding a meaningful return value — like `true` — or `null`, to the bottom of your function.

To step through a range comprehension in fixed-size chunks, use `by`, for example:
`evens = (x for x in [0..10] by 2)`

If you don’t need the current iteration value you may omit it:
`browser.closeCurrentTab() for [0...count]`

Comprehensions can also be used to iterate over the keys and values in an object. Use `of` to signal comprehension over the properties of an object instead of the values in an array.

```
codeFor('object_comprehensions', 'ages.join(", ")')
```

If you would like to iterate over just the keys that are defined on the object itself, by adding a `hasOwnProperty` check to avoid properties that may be inherited from the prototype, use `for own key, value of object`.

To iterate a generator function, use `from`. See [Generator Functions](#generator-iteration).

The only low-level loop that CoffeeScript provides is the `while` loop. The main difference from JavaScript is that the `while` loop can be used as an expression, returning an array containing the result of each iteration through the loop.

```
codeFor('while', 'lyrics.join("\\n")')
```

For readability, the `until` keyword is equivalent to `while not`, and the `loop` keyword is equivalent to `while true`.

When using a JavaScript loop to generate functions, it’s common to insert a closure wrapper in order to ensure that loop variables are closed over, and all the generated functions don’t just share the final values. CoffeeScript provides the `do` keyword, which immediately invokes a passed function, forwarding any arguments.

```
codeFor('do')
```
