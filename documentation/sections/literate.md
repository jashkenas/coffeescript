## Literate CoffeeScript

Besides being used as an ordinary programming language, CoffeeScript may also be written in “literate” mode. If you name your file with a `.litcoffee` extension, you can write it as a Markdown document — a document that also happens to be executable CoffeeScript code. The compiler will treat any indented blocks (Markdown’s way of indicating source code) as code, and ignore the rest as comments.

Just for kicks, a little bit of the compiler is currently implemented in this fashion: See it [as a document](https://gist.github.com/jashkenas/3fc3c1a8b1009c00d9df), [raw](https://raw.github.com/jashkenas/coffeescript/master/src/scope.litcoffee), and [properly highlighted in a text editor](http://cl.ly/LxEu).

I’m fairly excited about this direction for the language, and am looking forward to writing (and more importantly, reading) more programs in this style. More information about Literate CoffeeScript, including an [example program](https://github.com/jashkenas/journo), are [available in this blog post](http://ashkenas.com/literate-coffeescript).
