## Function Modifiers

In JavaScript, the `this` keyword is dynamically scoped to mean the object that the current function is attached to. If you pass a function as a callback or attach it to a different object, the original value of `this` will be lost. If you’re not familiar with this behavior, [this Digital Web article](http://64.13.255.16/articles/scope_in_javascript/) gives a good overview of the quirks.

The fat arrow `=>` can be used to both define a function, and to bind it to the current value of `this`, right on the spot. This is helpful when using callback-based libraries like Prototype or jQuery, for creating iterator functions to pass to `each`, or event-handler functions to use with `on`. Functions created with the fat arrow are able to access properties of the `this` where they’re defined.

```
codeFor('fat_arrow')
```

If we had used `->` in the callback above, `@customer` would have referred to the undefined “customer” property of the DOM element, and trying to call `purchase()` on it would have raised an exception.

When used in a class definition, methods declared with the fat arrow will be automatically bound to each instance of the class when the instance is constructed.

CoffeeScript also supports [generator functions](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/function*) and [async functions](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function) through the `yield` and `await` keywords respectively. There's no `function*(){}` or `async function(){}` nonsense—a generator in CoffeeScript is simply a function that yields, and an async function in CoffeeScript is simply a function that awaits.

```
codeFor('generators', 'ps.next().value')
```

`yield*` is called `yield from`, and `yield return` may be used if you need to force a generator that doesn’t yield.

You can iterate over a generator function using `for…from`.

```
codeFor('generator_iteration', 'getFibonacciNumbers(10)')
```

Similar to how `yield return` forces a generator, `await return` may be used to force a function to be async.

```
codeFor('async', true)
```
