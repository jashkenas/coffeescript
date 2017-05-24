## `"text/coffeescript"` Script Tags

While it’s not recommended for serious use, CoffeeScripts may be included directly within the browser using `<script type="text/coffeescript">` tags. The source includes a compressed and minified version of the compiler ([Download current version here, 51k when gzipped](/v<%= majorVersion %>/browser-compiler/coffeescript.js)) as `docs/v<%= majorVersion %>/browser-compiler/coffeescript.js`. Include this file on a page with inline CoffeeScript tags, and it will compile and evaluate them in order.

In fact, the little bit of glue script that runs [Try CoffeeScript](#try), as well as the code examples and other interactive parts of this site, is implemented in just this way. View source and look at the bottom of the page to see the example. Including the script also gives you access to `CoffeeScript.compile()` so you can pop open your JavaScript console and try compiling some strings.

The usual caveats about CoffeeScript apply — your inline scripts will run within a closure wrapper, so if you want to expose global variables or functions, attach them to the `window` object.
