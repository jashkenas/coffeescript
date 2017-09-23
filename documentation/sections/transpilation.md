### Transpilation

CoffeeScript 2 generates JavaScript that uses the latest, modern syntax. Your runtime [might not support all of that syntax](#compatibility). If so, you need to _transpile_ the JavaScript. To make things a little easier, CoffeeScript has built-in support for the popular [Babel](http://babeljs.io/) transpiler.

#### Quickstart

From the root of your project:

```bash
npm install --save-dev babel-core babel-preset-env
echo '{ "presets": ["env"] }' > .babelrc
coffee --compile --transpile --inline-map some-file.coffee
```

#### About Transpilation

Transpilation is the conversion of source code into equivalent but different source code. In our case, we want to convert modern JavaScript into older JavaScript that will run in older versions of Node or older browsers; for example, `{ a } = obj` into `a = obj.a`. This is done via transpilers like [Babel](http://babeljs.io/), [Bublé](https://buble.surge.sh/) or [Traceur Compiler](https://github.com/google/traceur-compiler).

CoffeeScript includes a `--transpile` option when used via the `coffee` command, or a `transpile` option when used via Node. To use either, [Babel](http://babeljs.io/) must be installed in your project:

```bash
npm install --save-dev babel-core
```

Or if you’re running the `coffee` command outside of a project folder, using a globally-installed `coffeescript` module, `babel-core` also needs to be installed globally:

```bash
npm install --global babel-core
```

By default, Babel doesn’t do anything—it doesn’t make assumptions about what you want to transpile to. You might know that your code will run in Node 8, and so you want Babel to transpile modules and JSX and nothing else. Or you might want to support Internet Explorer 8, in which case Babel will transpile every feature introduced in ES2015 and later specs.

If you’re not sure what you need, a good starting point is [`babel-preset-env`](https://babeljs.io/docs/plugins/preset-env/):

```bash
npm install --save-dev babel-preset-env  # Or --global for non-project-based usage
```

See [Babel’s website to learn about presets and plugins](https://babeljs.io/docs/plugins/) and the multitude of options you have.

Simply installing `babel-preset-env` isn’t enough. You also need to define the configuration options that you want Babel to use. You can do this by creating a [`.babelrc` file](https://babeljs.io/docs/usage/babelrc/) in the folder containing the files you’re compiling, or in any parent folder up the path above those files. (Babel supports [other ways](https://babeljs.io/docs/usage/babelrc/) to specify its options; any of them will work, though for the sake of simplicity in these docs we’ll assume you’re creating a `.babelrc` file.) So if your project is in `~/app` and your files are in `~/app/src`, you can put `.babelrc` in either `~/app` or in `~/app/src`. A minimal `.babelrc` file (or `package.json` `babel` key) for use with `babel-preset-env` would be just `{ "presets": ["env"] }`.

Once you have `babel-core` and `babel-preset-env` (or other presets or plugins) installed, and a `.babelrc` file (or other equivalent file) in place, you can use `coffee --transpile` to pipe CoffeeScript’s output through Babel using the options you’ve saved.

If you’re using CoffeeScript via the [Node API](nodejs_usage), where you call `CoffeeScript.compile` with a string to be compiled and an `options` object, the `transpile` key of the `options` object should be the Babel options:

```js
CoffeeScript.compile(code, {transpile: {presets: ['env']}})
```

You can also transpile CoffeeScript’s output without using the `transpile` option, for example as part of a build chain. This lets you use transpilers other than Babel, and it gives you greater control over the process. There are many great task runners for setting up JavaScript build chains, such as [Gulp](http://gulpjs.com/), [Webpack](https://webpack.github.io/), [Grunt](https://gruntjs.com/) and [Broccoli](http://broccolijs.com/).

Note that [babel-preset-env](https://babeljs.io/docs/plugins/preset-env/) doesn’t automatically supply [polyfills](https://developer.mozilla.org/en-US/docs/Glossary/Polyfill) for your code. CoffeeScript itself will output [`Array.indexOf`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf) if you use the `in` operator, or destructuring or spread/rest syntax; and [`Function.bind`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind) if you use a bound (`=>`) method in a class. Both are supported in Internet Explorer 9+ and all more recent browsers, but you will need to supply polyfills if you need to support Internet Explorer 8 or below and are using features that would cause these methods to be output. You’ll also need to supply polyfills if your own code uses these methods or another method added in recent versions of JavaScript. One polyfill option is [`babel-polyfill`](https://babeljs.io/docs/usage/polyfill/), though there are many [other](https://hackernoon.com/polyfills-everything-you-ever-wanted-to-know-or-maybe-a-bit-less-7c8de164e423) [strategies](https://philipwalton.com/articles/loading-polyfills-only-when-needed/).
