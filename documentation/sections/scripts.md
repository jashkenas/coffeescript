## `"text/coffeescript"` Script Tags

While it’s not recommended for serious use, CoffeeScripts may be included directly within the browser using `<script type="text/coffeescript">` tags. The source includes a compressed and minified version of the compiler ([Download current version here, 77k when gzipped](/v<%= majorVersion %>/browser-compiler-legacy/coffeescript.js)) as `docs/v<%= majorVersion %>/browser-compiler-legacy/coffeescript.js`. Include this file on a page with inline CoffeeScript tags, and it will compile and evaluate them in order.

The usual caveats about CoffeeScript apply — your inline scripts will run within a closure wrapper, so if you want to expose global variables or functions, attach them to the `window` object.
