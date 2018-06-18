### Bound (fat arrow) functions

In CoffeeScript 1.x, `=>` compiled to a regular `function` but with references to `this`/`@` rewritten to use the outer scope’s `this`, or with the inner function bound to the outer scope via `.bind` (hence the name “bound function”). In CoffeeScript 2, `=>` compiles to [ES2015’s `=>`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/Arrow_functions), which behaves slightly differently. The largest difference is that in ES2015, `=>` functions lack an `arguments` object:

```
codeFor('breaking_change_fat_arrow', 'outer(1, 2)')
```