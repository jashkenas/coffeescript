### Compatibility

Most modern JavaScript features that CoffeeScript supports can run natively in Node 7.6+, meaning that Node can run CoffeeScript’s output without any further processing required. Here are some notable exceptions:

*  [JSX](#jsx) always requires transpilation.
*  [Modules](#modules) (`import` and `export` statements) are supported by Node 10+, provided you specify an output filename with an `.mjs` extension (or rename the extensions of the generated `.js` files) and execute such files via `node`, not `coffee`.
*  [Splats, a.k.a. object rest/spread syntax, for objects](http://coffeescript.org/#splats) are supported by Node 8.6+.
*  The [regular expression `s` (dotall) flag](https://github.com/tc39/proposal-regexp-dotall-flag) is supported by Node 9+.

This list may be incomplete, and excludes versions of Node that support newer features behind flags; please refer to [node.green](http://node.green/) for full details. You can [run the tests in your browser](test.html) to see what your browser supports. It is your responsibility to ensure that your runtime supports the modern features you use; or that you [transpile](#transpilation) your code. When in doubt, transpile.

Why doesn’t CoffeeScript 2 simply always transpile? Because outputting modern JavaScript syntax is required for compatibility with frameworks that assume modern features. CoffeeScript needs to output classes using the `class` keyword in order allow you to `extend` a JavaScript class; extending such classes was impossible in CoffeeScript 1. Parity in how language features work is also important on its own; CoffeeScript “is just JavaScript,” and so things like [function parameter default values](#breaking-changes-default-values) should behave the same in CoffeeScript as in JavaScript. Some such features behave slightly differently in JavaScript than they did in CoffeeScript 1; in such cases we are conforming with the JavaScript spec, and we’ve documented the differences as [breaking changes](#breaking-changes).
