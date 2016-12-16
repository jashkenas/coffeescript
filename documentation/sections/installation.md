## Installation

The CoffeeScript compiler is itself [written in CoffeeScript](v<%= majorVersion %>/annotated-source/grammar.html), using the [Jison parser generator](http://jison.org). The command-line version of `coffee` is available as a [Node.js](http://nodejs.org/) utility. The [core compiler](v<%= majorVersion %>/browser-compiler/coffee-script.js) however, does not depend on Node, and can be run in any JavaScript environment, or in the browser (see “Try CoffeeScript”, above).

To install, first make sure you have a working copy of the latest stable version of [Node.js](http://nodejs.org/). You can then install CoffeeScript globally with [npm](http://npmjs.org):

> ```
npm install -g coffee-script
```

When you need CoffeeScript as a dependency, install it locally:

> ```
npm install --save coffee-script
```

If you’d prefer to install the latest **master** version of CoffeeScript, you can clone the CoffeeScript [source repository](http://github.com/jashkenas/coffeescript) from GitHub, or download [the source](http://github.com/jashkenas/coffeescript/tarball/master) directly. To install the latest master CoffeeScript compiler with npm:

> ```
npm install -g jashkenas/coffeescript
```

Or, if you want to install to `/usr/local`, and don’t want to use npm to manage it, open the `coffee-script` directory and run:

> ```
sudo bin/cake install
```
