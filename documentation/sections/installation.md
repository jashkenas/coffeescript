## Installation

The command-line version of `coffee` is available as a [Node.js](https://nodejs.org/) utility, requiring Node 6 or later. The [core compiler](/v<%= majorVersion %>/browser-compiler/coffeescript.js) however, does not depend on Node, and can be run in any JavaScript environment, or in the browser (see [Try CoffeeScript](#try)).

To install, first make sure you have a working copy of the latest stable version of [Node.js](https://nodejs.org/). You can then install CoffeeScript globally with [npm](https://www.npmjs.com/):

```bash
npm install --global coffeescript
```

This will make the `coffee` and `cake` commands available globally.

If you are using CoffeeScript in a project, you should install it locally for that project so that the version of CoffeeScript is tracked as one of your project’s dependencies. Within that project’s folder:

```bash
npm install --save-dev coffeescript
```

The `coffee` and `cake` commands will first look in the current folder to see if CoffeeScript is installed locally, and use that version if so. This allows different versions of CoffeeScript to be installed globally and locally.

If you plan to use the `--transpile` option (see [Transpilation](#transpilation)) you will need to also install `babel-core` either globally or locally, depending on whether you are running a globally or locally installed version of CoffeeScript.