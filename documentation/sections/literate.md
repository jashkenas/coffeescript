## Literate CoffeeScript

Besides being used as an ordinary programming language, CoffeeScript may also be written in “literate” mode. If you name your file with a `.litcoffee` extension, you can write it as a Markdown document — a document that also happens to be executable CoffeeScript code. The compiler will treat any indented blocks (Markdown’s way of indicating source code) as executable code, and ignore the rest as comments. Code blocks must also be separated from comments by at least one blank line.

Just for kicks, a little bit of the compiler is currently implemented in this fashion: See it [as a document](https://gist.github.com/jashkenas/3fc3c1a8b1009c00d9df), [raw](https://raw.githubusercontent.com/jashkenas/coffeescript/master/src/scope.litcoffee), and [properly highlighted in a text editor](http://cl.ly/LxEu).

A few caveats:

* Code blocks need to maintain consistent indentation relative to each other. When the compiler parses your Literate CoffeeScript file, it first discards all the non-code block lines and then parses the remainder as a regular CoffeeScript file. Therefore the code blocks need to be written as if the comment lines don’t exist, with consistent indentation (including whether they are indented with tabs or spaces).
* Along those lines, code blocks within list items or blockquotes are not treated as executable code. Since list items and blockquotes imply their own indentation, it would be ambiguous how to treat indentation between successive code blocks when some are within these other blocks and some are not.
* List items can be at most only one paragraph long. The second paragraph of a list item would be indented after a blank line, and therefore indistinguishable from a code block.
