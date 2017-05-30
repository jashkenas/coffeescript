### `get` and `set` keyword shorthand syntax

`get` and `set`, as keywords preceding functions or class methods, are intentionally unimplemented in CoffeeScript.

This is to avoid grammatical ambiguity, since in CoffeeScript such a construct looks identical to a function call (e.g. `get(function foo() {})`); and because there is an [alternate syntax](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty) that is slightly more verbose but just as effective:

```
codeFor('get_set', 'screen.height')
```
