### Compatibility

Most modern JavaScript features that CoffeeScript supports can run natively in Node 7.6+, meaning that Node can run CoffeeScript’s output without any further processing required. Here are some notable exceptions:

*  [JSX](#jsx) always requires transpilation.
*  [Modules](#modules) (`import` and `export` statements) are supported by Node 10+, provided you specify an output filename with an `.mjs` extension (or rename the extensions of the generated `.js` files) and execute such files via `node`, not `coffee`.
*  [Splats, a.k.a. object rest/spread syntax, for objects](http://coffeescript.org/#splats) are supported by Node 8.6+.
*  The [regular expression `s` (dotall) flag](https://github.com/tc39/proposal-regexp-dotall-flag) is supported by Node 9+.

This list may be incomplete, and excludes versions of Node that support newer features behind flags; please refer to [node.green](http://node.green/) for full details. You can [run the tests in your browser](test.html) to see what your browser supports. It is your responsibility to ensure that your runtime supports the modern features you use; or that you [transpile](#transpilation) your code. When in doubt, transpile.
