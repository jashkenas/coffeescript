## Everything is an Expression (at least, as much as possible)

You might have noticed how even though we don’t add return statements to CoffeeScript functions, they nonetheless return their final value. The CoffeeScript compiler tries to make sure that all statements in the language can be used as expressions. Watch how the `return` gets pushed down into each possible branch of execution in the function below.

```
codeFor('expressions', 'eldest')
```

Even though functions will always return their final value, it’s both possible and encouraged to return early from a function body writing out the explicit return (`return value`), when you know that you’re done.

Because variable declarations occur at the top of scope, assignment can be used within expressions, even for variables that haven’t been seen before:

```
codeFor('expressions_assignment', 'six')
```

Things that would otherwise be statements in JavaScript, when used as part of an expression in CoffeeScript, are converted into expressions by wrapping them in a closure. This lets you do useful things, like assign the result of a comprehension to a variable:

```
codeFor('expressions_comprehension', 'globals')
```

As well as silly things, like passing a `try`/`catch` statement directly into a function call:

```
codeFor('expressions_try', true)
```

There are a handful of statements in JavaScript that can’t be meaningfully converted into expressions, namely `break`, `continue`, and `return`. If you make use of them within a block of code, CoffeeScript won’t try to perform the conversion.
