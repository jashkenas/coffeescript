### ES2015+ Output

CoffeeScript 2 outputs the latest ES2015+ syntax. If you’re looking for a single tool that takes CoffeeScript input and generates JavaScript output that runs in any JavaScript runtime, assuming you opt out of certain newer features, stick to [CoffeeScript 1.x](/v1/). CoffeeScript 2 [breaks compatibility](#breaking-changes) with certain CoffeeScript 1.x features in order to conform with the ES2015+ specifications, and generate more idiomatic output (a CoffeeScript `=>` becomes an ES `=>`; a CoffeeScript `class` becomes an ES `class`; and so on).

Since the CoffeeScript 2 compiler outputs ES2015+ syntax, it is your responsibility to either ensure that your target JavaScript runtime(s) support all these features, or that you pass the output through another transpiler like [Babel](http://babeljs.io/), [Rollup](https://github.com/rollup/rollup) or [Traceur Compiler](https://github.com/google/traceur-compiler). In general, [CoffeeScript 2’s output is supported as is by Node.js 7.6+](http://node.green/), except for modules and JSX which require transpilation.

There are many great task runners for setting up JavaScript build chains, such as [Gulp](http://gulpjs.com/), [Webpack](https://webpack.github.io/), [Grunt](https://gruntjs.com/) and [Broccoli](http://broccolijs.com/). If you’re looking for a very minimal solution to get started, you can use [babel-preset-env](https://babeljs.io/docs/plugins/preset-env/) and the command line:

```bash
npm install --global coffeescript@next
npm install --save-dev coffeescript@next babel-cli babel-preset-env
coffee --print *.coffee | babel --presets env > app.js
```

Note that [babel-preset-env](https://babeljs.io/docs/plugins/preset-env/) doesn’t automatically supply polyfills for your code. CoffeeScript itself will output [`Array.indexOf`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf) if you use the `in` operator, or destructuring or spread/rest syntax; and [`Function.bind`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind) if you use a bound (`=>`) method in a class. Both are supported in Internet Explorer 9+ and all more recent browsers, but you will need to supply polyfills if you need to support Internet Explorer 8 or below and are using features that would cause these methods to be output, or in your own code are using similarly modern methods. One option is [`babel-polyfill`](https://babeljs.io/docs/usage/polyfill/), though there are many [other](https://hackernoon.com/polyfills-everything-you-ever-wanted-to-know-or-maybe-a-bit-less-7c8de164e423) [strategies](https://philipwalton.com/articles/loading-polyfills-only-when-needed/).
