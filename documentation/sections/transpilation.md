### Transpilation

CoffeeScript 2 generates JavaScript that uses the latest, modern syntax. The runtime or browsers where you want your code to run [might not support all of that syntax](#compatibility). In that case, we want to convert modern JavaScript into older JavaScript that will run in older versions of Node or older browsers; for example, `{ a } = obj` into `a = obj.a`. This is done via transpilers like [Babel](http://babeljs.io/), [Bublé](https://buble.surge.sh/) or [Traceur Compiler](https://github.com/google/traceur-compiler).

#### Quickstart

From the root of your project:

```bash
npm install --save-dev @babel/core @babel/preset-env
echo '{ "presets": ["@babel/env"] }' > .babelrc
coffee --compile --transpile --inline-map some-file.coffee
```

#### Transpiling with the CoffeeScript compiler

To make things easy, CoffeeScript has built-in support for the popular [Babel](http://babeljs.io/) transpiler. You can use it via the `--transpile` command-line option or the `transpile` Node API option. To use either, `@babel/core` must be installed in your project:

```bash
npm install --save-dev @babel/core
```

Or if you’re running the `coffee` command outside of a project folder, using a globally-installed `coffeescript` module, `@babel/core` needs to be installed globally:

```bash
npm install --global @babel/core
```

By default, Babel doesn’t do anything—it doesn’t make assumptions about what you want to transpile to. You need to provide it with a configuration so that it knows what to do. One way to do this is by creating a [`.babelrc` file](https://babeljs.io/docs/usage/babelrc/) in the folder containing the files you’re compiling, or in any parent folder up the path above those files. (Babel supports [other ways](https://babeljs.io/docs/usage/babelrc/), too.) A minimal `.babelrc` file would be just `{ "presets": ["@babel/env"] }`. This implies that you have installed [`@babel/preset-env`](https://babeljs.io/docs/plugins/preset-env/):

```bash
npm install --save-dev @babel/preset-env  # Or --global for non-project-based usage
```

See [Babel’s website to learn about presets and plugins](https://babeljs.io/docs/plugins/) and the multitude of options you have. Another preset you might need is [`@babel/plugin-transform-react-jsx`](https://babeljs.io/docs/en/babel-plugin-transform-react-jsx/) if you’re using JSX with React (JSX can also be used with other frameworks).

Once you have `@babel/core` and `@babel/preset-env` (or other presets or plugins) installed, and a `.babelrc` file (or other equivalent) in place, you can use `coffee --transpile` to pipe CoffeeScript’s output through Babel using the options you’ve saved.

If you’re using CoffeeScript via the [Node API](nodejs_usage), where you call `CoffeeScript.compile` with a string to be compiled and an `options` object, the `transpile` key of the `options` object should be the Babel options:

```js
CoffeeScript.compile(code, {transpile: {presets: ['@babel/env']}})
```

You can also transpile CoffeeScript’s output without using the `transpile` option, for example as part of a build chain. This lets you use transpilers other than Babel, and it gives you greater control over the process. There are many great task runners for setting up JavaScript build chains, such as [Gulp](http://gulpjs.com/), [Webpack](https://webpack.github.io/), [Grunt](https://gruntjs.com/) and [Broccoli](http://broccolijs.com/).

#### Polyfills

Note that transpiling doesn’t automatically supply [polyfills](https://developer.mozilla.org/en-US/docs/Glossary/Polyfill) for your code. CoffeeScript itself will output [`Array.indexOf`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf) if you use the `in` operator, or destructuring or spread/rest syntax; and [`Function.bind`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind) if you use a bound (`=>`) method in a class. Both are supported in Internet Explorer 9+ and all more recent browsers, but you will need to supply polyfills if you need to support Internet Explorer 8 or below and are using features that would cause these methods to be output. You’ll also need to supply polyfills if your own code uses these methods or another method added in recent versions of JavaScript. One polyfill option is [`@babel/polyfill`](https://babeljs.io/docs/en/babel-polyfill/), though there are many [other](https://hackernoon.com/polyfills-everything-you-ever-wanted-to-know-or-maybe-a-bit-less-7c8de164e423) [strategies](https://philipwalton.com/articles/loading-polyfills-only-when-needed/).
