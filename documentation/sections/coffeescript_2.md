## CoffeeScript 2

### Why CoffeeScript When There’s ES2015+?

CoffeeScript introduced many new features to the JavaScript world, such as [`=>`](#fat-arrow) and [destructuring](#destructuring) and [classes](#classes). We are happy that ECMA has seen their utility and adopted them into ECMAScript.

CoffeeScript’s intent, however, was never to be a superset of JavaScript. One of the guiding principles of CoffeeScript has been _simplicity:_ not just removing JavaScript’s “bad parts,” but providing a cleaner, terser syntax that uses less punctuation and enforces indentation, to make code easier to read and reason about. Increased clarity leads to increased quality, and fewer bugs. This benefit of CoffeeScript remains, even in an ES2015+ world.

### ES2015+ Output

CoffeeScript 2 supports many of the latest ES2015+ features, output using ES2015+ syntax. If you’re looking for a single tool that takes CoffeeScript input and generates JavaScript output that runs in any JavaScript runtime, assuming you opt out of certain newer features, stick to the [CoffeeScript 1.x branch](/v1/). CoffeeScript 2 [breaks compatibility](#breaking-changes) with certain CoffeeScript 1.x features in order to conform with the ES2015+ specifications, and generate more idiomatic output (a CoffeeScript `=>` becomes an ES `=>`; a CoffeeScript `class` becomes an ES `class`; and so on).

Since the CoffeeScript 2 compiler outputs ES2015+ syntax, it is your responsibility to either ensure that your target JavaScript runtime(s) support all these features, or that you pass the output through another transpiler like [Babel](http://babeljs.io/), [Rollup](https://github.com/rollup/rollup) or [Traceur Compiler](https://github.com/google/traceur-compiler). In general, [CoffeeScript 2’s output is supported as is by Node.js 7.6+](http://node.green/), except for modules which require transpilation.

There are many great task runners for setting up JavaScript build chains, such as [Gulp](http://gulpjs.com/), [Webpack](https://webpack.github.io/), [Grunt](https://gruntjs.com/) and [Broccoli](http://broccolijs.com/). If you’re looking for a very minimal solution to get started, you can use [babel-preset-env](https://babeljs.io/docs/plugins/preset-env/) and the command line:

```bash
npm install --global coffeescript@next
npm install --save-dev coffeescript@next babel-cli babel-preset-env
coffee -p *.coffee | babel --presets env > app.js
```
