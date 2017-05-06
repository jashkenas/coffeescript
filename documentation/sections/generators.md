## Generator Functions

CoffeeScript supports ES2015 [generator functions](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/function*) through the `yield` keyword. There's no `function*(){}` nonsense — a generator in CoffeeScript is simply a function that yields.

```
codeFor('generators', 'ps.next().value')
```

`yield*` is called `yield from`, and `yield return` may be used if you need to force a generator that doesn’t yield.

<div id="generator-iteration" class="bookmark"></div>

You can iterate over a generator function using `for…from`.

```
codeFor('generator_iteration', 'getFibonacciNumbers(10)')
```
