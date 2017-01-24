## Change Log

```
releaseHeader('2017-01-24', '1.12.3', '1.12.2')
```

*   `@` values can now be used as indices in `for` expressions. This loosens the compilation of `for` expressions to allow the index variable to be an `@` value, e.g. `do @visit for @node, @index in nodes`. Within `@visit`, the index of the current node (`@node`) would be available as `@index`.
*   CoffeeScript’s patched `Error.prepareStackTrace` has been restored, with some revisions that should prevent the erroneous exceptions that were making life difficult for some downstream projects. This fixes the incorrect line numbers in stack traces since 1.12.2.
*   The `//=` operator’s output now wraps parentheses around the right operand, like the other assignment operators.

```
releaseHeader('2016-12-16', '1.12.2', '1.12.1')
```

*   The browser compiler can once again be built unminified via `MINIFY=false cake build:browser`.
*   The error-prone patched version of `Error.prepareStackTrace` has been removed.
*   Command completion in the REPL (pressing tab to get suggestions) has been fixed for Node 6.9.1+.
*   The [browser-based tests](v<%= majorVersion %>/test.html) now include all the tests as the Node-based version.

```
releaseHeader('2016-12-07', '1.12.1', '1.12.0')
```

*   You can now import a module member named `default`, e.g. `import { default } from 'lib'`. Though like in ES2015, you cannot import an entire module and name it `default` (so `import default from 'lib'` is not allowed).
*   Fix regression where `from` as a variable name was breaking `for` loop declarations. For the record, `from` is not a reserved word in CoffeeScript; you may use it for variable names. `from` behaves like a keyword within the context of `import` and `export` statements, and in the declaration of a `for` loop; though you should also be able to use variables named `from` in those contexts, and the compiler should be able to tell the difference.

```
releaseHeader('2016-12-04', '1.12.0', '1.11.1')
```

*   CoffeeScript now supports ES2015 [tagged template literals](#tagged-template-literals). Note that using tagged template literals in your code makes you responsible for ensuring that either your runtime supports tagged template literals or that you transpile the output JavaScript further to a version your target runtime(s) support.
*   CoffeeScript now provides a [`for…from`](#generator-iteration) syntax for outputting ES2015 [`for…of`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/for...of). (Sorry they couldn’t match, but we came up with `for…of` first for something else.) This allows iterating over generators or any other iterable object. Note that using `for…from` in your code makes you responsible for ensuring that either your runtime supports `for…of` or that you transpile the output JavaScript further to a version your target runtime(s) support.
*   Triple backticks (`` ```​``) allow the creation of embedded JavaScript blocks where escaping single backticks is not required, which should improve interoperability with ES2015 template literals and with Markdown.
*   Within single-backtick embedded JavaScript, backticks can now be escaped via `` \`​``.
*   The browser tests now run in the browser again, and are accessible [here](v<%= majorVersion %>/test.html) if you would like to test your browser.
*   CoffeeScript-only keywords in ES2015 `import`s and `export`s are now ignored.
*   The compiler now throws an error on trying to export an anonymous class.
*   Bugfixes related to tokens and location data, for better source maps and improved compatibility with downstream tools.

```
releaseHeader('2016-10-02', '1.11.1', '1.11.0')
```

*   Bugfix for shorthand object syntax after interpolated keys.
*   Bugfix for indentation-stripping in `"""` strings.
*   Bugfix for not being able to use the name “arguments” for a prototype property of class.
*   Correctly compile large hexadecimal numbers literals to `2e308` (just like all other large number literals do).

```
releaseHeader('2016-09-24', '1.11.0', '1.10.0')
```

*   CoffeeScript now supports ES2015 [`import` and `export` syntax](#modules).
*   Added the `-M, --inline-map` flag to the compiler, allowing you embed the source map directly into the output JavaScript, rather than as a separate file.
*   A bunch of fixes for `yield`:

    *   `yield return` can no longer mistakenly be used as an expression.
    *   `yield` now mirrors `return` in that it can be used stand-alone as well as with expressions. Where you previously wrote `yield undefined`, you may now write simply `yield`. However, this means also inheriting the same syntax limitations that `return` has, so these examples no longer compile:
        ```
        doubles = ->
          yield for i in [1..3]
            i * 2
        six = ->
          yield
            2 * 3
        ```

    *   The JavaScript output is a bit nicer, with unnecessary parentheses and spaces, double indentation and double semicolons around `yield` no longer present.
*   `&&=`, `||=`, `and=` and `or=` no longer accidentally allow a space before the equals sign.
*   Improved several error messages.
*   Just like `undefined` compiles to `void 0`, `NaN` now compiles into `0/0` and `Infinity` into `2e308`.
*   Bugfix for renamed destructured parameters with defaults. `({a: b = 1}) ->` no longer crashes the compiler.
*   Improved the internal representation of a CoffeeScript program. This is only noticeable to tools that use `CoffeeScript.tokens` or `CoffeeScript.nodes`. Such tools need to update to take account for changed or added tokens and nodes.
*   Several minor bug fixes, including:

    *   The caught error in `catch` blocks is no longer declared unnecessarily, and no longer mistakenly named `undefined` for `catch`-less `try` blocks.
    *   Unassignable parameter destructuring no longer crashes the compiler.
    *   Source maps are now used correctly for errors thrown from .coffee.md files.
    *   `coffee -e 'throw null'` no longer crashes.
    *   The REPL no longer crashes when using `.exit` to exit it.
    *   Invalid JavaScript is no longer output when lots of `for` loops are used in the same scope.
    *   A unicode issue when using stdin with the CLI.

```
releaseHeader('2015-09-03', '1.10.0', '1.9.3')
```

*   CoffeeScript now supports ES2015-style destructuring defaults.
*   `(offsetHeight: height) ->` no longer compiles. That syntax was accidental and partly broken. Use `({offsetHeight: height}) ->` instead. Object destructuring always requires braces.
*   Several minor bug fixes, including:

    *   A bug where the REPL would sometimes report valid code as invalid, based on what you had typed earlier.
    *   A problem with multiple JS contexts in the jest test framework.
    *   An error in io.js where strict mode is set on internal modules.
    *   A variable name clash for the caught error in `catch` blocks.

```
releaseHeader('2015-05-27', '1.9.3', '1.9.2')
```

*   Bugfix for interpolation in the first key of an object literal in an implicit call.
*   Fixed broken error messages in the REPL, as well as a few minor bugs with the REPL.
*   Fixed source mappings for tokens at the beginning of lines when compiling with the `--bare` option. This has the nice side effect of generating smaller source maps.
*   Slight formatting improvement of compiled block comments.
*   Better error messages for `on`, `off`, `yes` and `no`.

```
releaseHeader('2015-04-15', '1.9.2', '1.9.1')
```

*   Fixed a **watch** mode error introduced in 1.9.1 when compiling multiple files with the same filename.
*   Bugfix for `yield` around expressions containing `this`.
*   Added a Ruby-style `-r` option to the REPL, which allows requiring a module before execution with `--eval` or `--interactive`.
*   In `<script type="text/coffeescript">` tags, to avoid possible duplicate browser requests for .coffee files, you can now use the `data-src` attribute instead of `src`.
*   Minor bug fixes for IE8, strict ES5 regular expressions and Browserify.

```
releaseHeader('2015-02-18', '1.9.1', '1.9.0')
```

*   Interpolation now works in object literal keys (again). You can use this to dynamically name properties.
*   Internal compiler variable names no longer start with underscores. This makes the generated JavaScript a bit prettier, and also fixes an issue with the completely broken and ungodly way that AngularJS “parses” function arguments.
*   Fixed a few `yield`-related edge cases with `yield return` and `yield throw`.
*   Minor bug fixes and various improvements to compiler error messages.

```
releaseHeader('2015-01-29', '1.9.0', '1.8.0')
```

*   CoffeeScript now supports ES2015 generators. A generator is simply a function that `yield`s.
*   More robust parsing and improved error messages for strings and regexes — especially with respect to interpolation.
*   Changed strategy for the generation of internal compiler variable names. Note that this means that `@example` function parameters are no longer available as naked `example` variables within the function body.
*   Fixed REPL compatibility with latest versions of Node and Io.js.
*   Various minor bug fixes.

```
releaseHeader('2014-08-26', '1.8.0', '1.7.1')
```

*   The `--join` option of the CLI is now deprecated.
*   Source maps now use `.js.map` as file extension, instead of just `.map`.
*   The CLI now exits with the exit code 1 when it fails to write a file to disk.
*   The compiler no longer crashes on unterminated, single-quoted strings.
*   Fixed location data for string interpolations, which made source maps out of sync.
*   The error marker in error messages is now correctly positioned if the code is indented with tabs.
*   Fixed a slight formatting error in CoffeeScript’s source map-patched stack traces.
*   The `%%` operator now coerces its right operand only once.
*   It is now possible to require CoffeeScript files from Cakefiles without having to register the compiler first.
*   The CoffeeScript REPL is now exported and can be required using `require 'coffee-script/repl'`.
*   Fixes for the REPL in Node 0.11.

```
releaseHeader('2014-01-29', '1.7.1', '1.7.0')
```

*   Fixed a typo that broke node module lookup when running a script directly with the `coffee` binary.

```
releaseHeader('2014-01-28', '1.7.0', '1.6.3')
```

*   When requiring CoffeeScript files in Node you must now explicitly register the compiler. This can be done with `require 'coffee-script/register'` or `CoffeeScript.register()`. Also for configuration such as Mocha’s, use **coffee-script/register**.
*   Improved error messages, source maps and stack traces. Source maps now use the updated `//#` syntax.
*   Leading `.` now closes all open calls, allowing for simpler chaining syntax.

```
codeFor('chaining')
```

*   Added `**`, `//` and `%%` operators and `...` expansion in parameter lists and destructuring expressions.
*   Multiline strings are now joined by a single space and ignore all indentation. A backslash at the end of a line can denote the amount of whitespace between lines, in both strings and heredocs. Backslashes correctly escape whitespace in block regexes.
*   Closing brackets can now be indented and therefore no longer cause unexpected error.
*   Several breaking compilation fixes. Non-callable literals (strings, numbers etc.) don’t compile in a call now and multiple postfix conditionals compile properly. Postfix conditionals and loops always bind object literals. Conditional assignment compiles properly in subexpressions. `super` is disallowed outside of methods and works correctly inside `for` loops.
*   Formatting of compiled block comments has been improved.
*   No more `-p` folders on Windows.
*   The `options` object passed to CoffeeScript is no longer mutated.

```
releaseHeader('2013-06-02', '1.6.3', '1.6.2')
```

*   The CoffeeScript REPL now remembers your history between sessions. Just like a proper REPL should.
*   You can now use `require` in Node to load `.coffee.md` Literate CoffeeScript files. In the browser, `text/literate-coffeescript` script tags.
*   The old `coffee --lint` command has been removed. It was useful while originally working on the compiler, but has been surpassed by JSHint. You may now use `-l` to pass literate files in over **stdio**.
*   Bugfixes for Windows path separators, `catch` without naming the error, and executable-class-bodies-with- prototypal-property-attachment.

```
releaseHeader('2013-03-18', '1.6.2', '1.6.1')
```

*   Source maps have been used to provide automatic line-mapping when running CoffeeScript directly via the `coffee` command, and for automatic line-mapping when running CoffeeScript directly in the browser. Also, to provide better error messages for semantic errors thrown by the compiler — [with colors, even](http://cl.ly/NdOA).
*   Improved support for mixed literate/vanilla-style CoffeeScript projects, and generating source maps for both at the same time.
*   Fixes for **1.6.x** regressions with overriding inherited bound functions, and for Windows file path management.
*   The `coffee` command can now correctly `fork()` both `.coffee` and `.js` files. (Requires Node.js 0.9+)

```
releaseHeader('2013-03-05', '1.6.1', '1.5.0')
```

*   First release of [source maps](#source-maps). Pass the `--map` flag to the compiler, and off you go. Direct all your thanks over to [Jason Walton](http://github.com/jwalton).
*   Fixed a 1.5.0 regression with multiple implicit calls against an indented implicit object. Combinations of implicit function calls and implicit objects should generally be parsed better now — but it still isn’t good _style_ to nest them too heavily.
*   `.coffee.md` is now also supported as a Literate CoffeeScript file extension, for existing tooling. `.litcoffee` remains the canonical one.
*   Several minor fixes surrounding member properties, bound methods and `super` in class declarations.

```
releaseHeader('2013-02-25', '1.5.0', '1.4.0')
```

*   First release of [Literate CoffeeScript](#literate).
*   The CoffeeScript REPL is now based on the Node.js REPL, and should work better and more familiarly.
*   Returning explicit values from constructors is now forbidden. If you want to return an arbitrary value, use a function, not a constructor.
*   You can now loop over an array backwards, without having to manually deal with the indexes: `for item in list by -1`
*   Source locations are now preserved in the CoffeeScript AST, although source maps are not yet being emitted.

```
releaseHeader('2012-10-23', '1.4.0', '1.3.3')
```

*   The CoffeeScript compiler now strips Microsoft’s UTF-8 BOM if it exists, allowing you to compile BOM-borked source files.
*   Fix Node/compiler deprecation warnings by removing `registerExtension`, and moving from `path.exists` to `fs.exists`.
*   Small tweaks to splat compilation, backticks, slicing, and the error for duplicate keys in object literals.

```
releaseHeader('2012-05-15', '1.3.3', '1.3.1')
```

*   Due to the new semantics of JavaScript’s strict mode, CoffeeScript no longer guarantees that constructor functions have names in all runtimes. See [#2052](https://github.com/jashkenas/coffeescript/issues/2052) for discussion.
*   Inside of a nested function inside of an instance method, it’s now possible to call `super` more reliably (walks recursively up).
*   Named loop variables no longer have different scoping heuristics than other local variables. (Reverts #643)
*   Fix for splats nested within the LHS of destructuring assignment.
*   Corrections to our compile time strict mode forbidding of octal literals.

```
releaseHeader('2012-04-10', '1.3.1', '1.2.0')
```

*   CoffeeScript now enforces all of JavaScript’s **Strict Mode** early syntax errors at compile time. This includes old-style octal literals, duplicate property names in object literals, duplicate parameters in a function definition, deleting naked variables, setting the value of `eval` or `arguments`, and more. See a full discussion at [#1547](https://github.com/jashkenas/coffeescript/issues/1547).
*   The REPL now has a handy new multi-line mode for entering large blocks of code. It’s useful when copy-and-pasting examples into the REPL. Enter multi-line mode with `Ctrl-V`. You may also now pipe input directly into the REPL.
*   CoffeeScript now prints a `Generated by CoffeeScript VERSION` header at the top of each compiled file.
*   Conditional assignment of previously undefined variables `a or= b` is now considered a syntax error.
*   A tweak to the semantics of `do`, which can now be used to more easily simulate a namespace: `do (x = 1, y = 2) -> …`
*   Loop indices are now mutable within a loop iteration, and immutable between them.
*   Both endpoints of a slice are now allowed to be omitted for consistency, effectively creating a shallow copy of the list.
*   Additional tweaks and improvements to `coffee --watch` under Node’s “new” file watching API. Watch will now beep by default if you introduce a syntax error into a watched script. We also now ignore hidden directories by default when watching recursively.

```
releaseHeader('2011-12-18', '1.2.0', '1.1.3')
```

*   Multiple improvements to `coffee --watch` and `--join`. You may now use both together, as well as add and remove files and directories within a `--watch`’d folder.
*   The `throw` statement can now be used as part of an expression.
*   Block comments at the top of the file will now appear outside of the safety closure wrapper.
*   Fixed a number of minor 1.1.3 regressions having to do with trailing operators and unfinished lines, and a more major 1.1.3 regression that caused bound functions _within_ bound class functions to have the incorrect `this`.

```
releaseHeader('2011-11-08', '1.1.3', '1.1.2')
```

*   Ahh, whitespace. CoffeeScript’s compiled JS now tries to space things out and keep it readable, as you can see in the examples on this page.
*   You can now call `super` in class level methods in class bodies, and bound class methods now preserve their correct context.
*   JavaScript has always supported octal numbers `010 is 8`, and hexadecimal numbers `0xf is 15`, but CoffeeScript now also supports binary numbers: `0b10 is 2`.
*   The CoffeeScript module has been nested under a subdirectory to make it easier to `require` individual components separately, without having to use **npm**. For example, after adding the CoffeeScript folder to your path: `require('coffee-script/lexer')`
*   There’s a new “link” feature in Try CoffeeScript on this webpage. Use it to get a shareable permalink for your example script.
*   The `coffee --watch` feature now only works on Node.js 0.6.0 and higher, but now also works properly on Windows.
*   Lots of small bug fixes from **[@michaelficarra](https://github.com/michaelficarra)**, **[@geraldalewis](https://github.com/geraldalewis)**, **[@satyr](https://github.com/satyr)**, and **[@trevorburnham](https://github.com/trevorburnham)**.

```
releaseHeader('2011-08-04', '1.1.2', '1.1.1')
```

Fixes for block comment formatting, `?=` compilation, implicit calls against control structures, implicit invocation of a try/catch block, variadic arguments leaking from local scope, line numbers in syntax errors following heregexes, property access on parenthesized number literals, bound class methods and super with reserved names, a REPL overhaul, consecutive compiled semicolons, block comments in implicitly called objects, and a Chrome bug.

```
releaseHeader('2011-05-10', '1.1.1', '1.1.0')
```

Bugfix release for classes with external constructor functions, see issue #1182.

```
releaseHeader('2011-05-01', '1.1.0', '1.0.1')
```

When running via the `coffee` executable, `process.argv` and friends now report `coffee` instead of `node`. Better compatibility with **Node.js 0.4.x** module lookup changes. The output in the REPL is now colorized, like Node’s is. Giving your concatenated CoffeeScripts a name when using `--join` is now mandatory. Fix for lexing compound division `/=` as a regex accidentally. All `text/coffeescript` tags should now execute in the order they’re included. Fixed an issue with extended subclasses using external constructor functions. Fixed an edge-case infinite loop in `addImplicitParentheses`. Fixed exponential slowdown with long chains of function calls. Globals no longer leak into the CoffeeScript REPL. Splatted parameters are declared local to the function.

```
releaseHeader('2011-01-31', '1.0.1', '1.0.0')
```

Fixed a lexer bug with Unicode identifiers. Updated REPL for compatibility with Node.js 0.3.7\. Fixed requiring relative paths in the REPL. Trailing `return` and `return undefined` are now optimized away. Stopped requiring the core Node.js `util` module for back-compatibility with Node.js 0.2.5\. Fixed a case where a conditional `return` would cause fallthrough in a `switch` statement. Optimized empty objects in destructuring assignment.

```
releaseHeader('2010-12-24', '1.0.0', '0.9.6')
```

CoffeeScript loops no longer try to preserve block scope when functions are being generated within the loop body. Instead, you can use the `do` keyword to create a convenient closure wrapper. Added a `--nodejs` flag for passing through options directly to the `node` executable. Better behavior around the use of pure statements within expressions. Fixed inclusive slicing through `-1`, for all browsers, and splicing with arbitrary expressions as endpoints.

```
releaseHeader('2010-12-06', '0.9.6', '0.9.5')
```

The REPL now properly formats stacktraces, and stays alive through asynchronous exceptions. Using `--watch` now prints timestamps as files are compiled. Fixed some accidentally-leaking variables within plucked closure-loops. Constructors now maintain their declaration location within a class body. Dynamic object keys were removed. Nested classes are now supported. Fixes execution context for naked splatted functions. Bugfix for inversion of chained comparisons. Chained class instantiation now works properly with splats.

```
releaseHeader('2010-11-21', '0.9.5', '0.9.4')
```

0.9.5 should be considered the first release candidate for CoffeeScript 1.0. There have been a large number of internal changes since the previous release, many contributed from **satyr**’s [Coco](http://github.com/satyr/coco) dialect of CoffeeScript. Heregexes (extended regexes) were added. Functions can now have default arguments. Class bodies are now executable code. Improved syntax errors for invalid CoffeeScript. `undefined` now works like `null`, and cannot be assigned a new value. There was a precedence change with respect to single-line comprehensions: `result = i for i in list`
used to parse as `result = (i for i in list)` by default … it now parses as
`(result = i) for i in list`.

```
releaseHeader('2010-09-21', '0.9.4', '0.9.3')
```

CoffeeScript now uses appropriately-named temporary variables, and recycles their references after use. Added `require.extensions` support for **Node.js 0.3**. Loading CoffeeScript in the browser now adds just a single `CoffeeScript` object to global scope. Fixes for implicit object and block comment edge cases.

```
releaseHeader('2010-09-16', '0.9.3', '0.9.2')
```

CoffeeScript `switch` statements now compile into JS `switch` statements — they previously compiled into `if/else` chains for JavaScript 1.3 compatibility. Soaking a function invocation is now supported. Users of the RubyMine editor should now be able to use `--watch` mode.

```
releaseHeader('2010-08-23', '0.9.2', '0.9.1')
```

Specifying the start and end of a range literal is now optional, eg. `array[3..]`. You can now say `a not instanceof b`. Fixed important bugs with nested significant and non-significant indentation (Issue #637). Added a `--require` flag that allows you to hook into the `coffee` command. Added a custom `jsl.conf` file for our preferred JavaScriptLint setup. Sped up Jison grammar compilation time by flattening rules for operations. Block comments can now be used with JavaScript-minifier-friendly syntax. Added JavaScript’s compound assignment bitwise operators. Bugfixes to implicit object literals with leading number and string keys, as the subject of implicit calls, and as part of compound assignment.

```
releaseHeader('2010-08-11', '0.9.1', '0.9.0')
```

Bugfix release for **0.9.1**. Greatly improves the handling of mixed implicit objects, implicit function calls, and implicit indentation. String and regex interpolation is now strictly `#{ … }` (Ruby style). The compiler now takes a `--require` flag, which specifies scripts to run before compilation.

```
releaseHeader('2010-08-04', '0.9.0', '0.7.2')
```

The CoffeeScript **0.9** series is considered to be a release candidate for **1.0**; let’s give her a shakedown cruise. **0.9.0** introduces a massive backwards-incompatible change: Assignment now uses `=`, and object literals use `:`, as in JavaScript. This allows us to have implicit object literals, and YAML-style object definitions. Half assignments are removed, in favor of `+=`, `or=`, and friends. Interpolation now uses a hash mark `#` instead of the dollar sign `$` — because dollar signs may be part of a valid JS identifier. Downwards range comprehensions are now safe again, and are optimized to straight for loops when created with integer endpoints. A fast, unguarded form of object comprehension was added: `for all key, value of object`. Mentioning the `super` keyword with no arguments now forwards all arguments passed to the function, as in Ruby. If you extend class `B` from parent class `A`, if `A` has an `extended` method defined, it will be called, passing in `B` — this enables static inheritance, among other things. Cleaner output for functions bound with the fat arrow. `@variables` can now be used in parameter lists, with the parameter being automatically set as a property on the object — useful in constructors and setter functions. Constructor functions can now take splats.

```
releaseHeader('2010-07-12', '0.7.2', '0.7.1')
```

Quick bugfix (right after 0.7.1) for a problem that prevented `coffee` command-line options from being parsed in some circumstances.

```
releaseHeader('2010-07-11', '0.7.1', '0.7.0')
```

Block-style comments are now passed through and printed as JavaScript block comments – making them useful for licenses and copyright headers. Better support for running coffee scripts standalone via hashbangs. Improved syntax errors for tokens that are not in the grammar.

```
releaseHeader('2010-06-28', '0.7.0', '0.6.2')
```

Official CoffeeScript variable style is now camelCase, as in JavaScript. Reserved words are now allowed as object keys, and will be quoted for you. Range comprehensions now generate cleaner code, but you have to specify `by -1` if you’d like to iterate downward. Reporting of syntax errors is greatly improved from the previous release. Running `coffee` with no arguments now launches the REPL, with Readline support. The `<-` bind operator has been removed from CoffeeScript. The `loop` keyword was added, which is equivalent to a `while true` loop. Comprehensions that contain closures will now close over their variables, like the semantics of a `forEach`. You can now use bound function in class definitions (bound to the instance). For consistency, `a in b` is now an array presence check, and `a of b` is an object-key check. Comments are no longer passed through to the generated JavaScript.

```
releaseHeader('2010-05-15', '0.6.2', '0.6.1')
```

The `coffee` command will now preserve directory structure when compiling a directory full of scripts. Fixed two omissions that were preventing the CoffeeScript compiler from running live within Internet Explorer. There’s now a syntax for block comments, similar in spirit to CoffeeScript’s heredocs. ECMA Harmony DRY-style pattern matching is now supported, where the name of the property is the same as the name of the value: `{name, length}: func`. Pattern matching is now allowed within comprehension variables. `unless` is now allowed in block form. `until` loops were added, as the inverse of `while` loops. `switch` statements are now allowed without switch object clauses. Compatible with Node.js **v0.1.95**.

```
releaseHeader('2010-04-12', '0.6.1', '0.6.0')
```

Upgraded CoffeeScript for compatibility with the new Node.js **v0.1.90** series.

```
releaseHeader('2010-04-03', '0.6.0', '0.5.6')
```

Trailing commas are now allowed, a-la Python. Static properties may be assigned directly within class definitions, using `@property` notation.

```
releaseHeader('2010-03-23', '0.5.6', '0.5.5')
```

Interpolation can now be used within regular expressions and heredocs, as well as strings. Added the `<-` bind operator. Allowing assignment to half-expressions instead of special `||=`-style operators. The arguments object is no longer automatically converted into an array. After requiring `coffee-script`, Node.js can now directly load `.coffee` files, thanks to **registerExtension**. Multiple splats can now be used in function calls, arrays, and pattern matching.

```
releaseHeader('2010-03-08', '0.5.5', '0.5.4')
```

String interpolation, contributed by [Stan Angeloff](http://github.com/StanAngeloff). Since `--run` has been the default since **0.5.3**, updating `--stdio` and `--eval` to run by default, pass `--compile` as well if you’d like to print the result.

```
releaseHeader('2010-03-03', '0.5.4', '0.5.3')
```

Bugfix that corrects the Node.js global constants `__filename` and `__dirname`. Tweaks for more flexible parsing of nested function literals and improperly-indented comments. Updates for the latest Node.js API.

```
releaseHeader('2010-02-27', '0.5.3', '0.5.2')
```

CoffeeScript now has a syntax for defining classes. Many of the core components (Nodes, Lexer, Rewriter, Scope, Optparse) are using them. Cakefiles can use `optparse.coffee` to define options for tasks. `--run` is now the default flag for the `coffee` command, use `--compile` to save JavaScripts. Bugfix for an ambiguity between RegExp literals and chained divisions.

```
releaseHeader('2010-02-25', '0.5.2', '0.5.1')
```

Added a compressed version of the compiler for inclusion in web pages as
`v<%= majorVersion %>/browser-compiler/coffee-script.js`. It’ll automatically run any script tags with type `text/coffeescript` for you. Added a `--stdio` option to the `coffee` command, for piped-in compiles.

```
releaseHeader('2010-02-24', '0.5.1', '0.5.0')
```

Improvements to null soaking with the existential operator, including soaks on indexed properties. Added conditions to `while` loops, so you can use them as filters with `when`, in the same manner as comprehensions.

```
releaseHeader('2010-02-21', '0.5.0', '0.3.2')
```

CoffeeScript 0.5.0 is a major release, While there are no language changes, the Ruby compiler has been removed in favor of a self-hosting compiler written in pure CoffeeScript.

```
releaseHeader('2010-02-08', '0.3.2', '0.3.0')
```

`@property` is now a shorthand for `this.property`.
Switched the default JavaScript engine from Narwhal to Node.js. Pass the `--narwhal` flag if you’d like to continue using it.

```
releaseHeader('2010-01-26', '0.3.0', '0.2.6')
```

CoffeeScript 0.3 includes major syntax changes:
The function symbol was changed to `->`, and the bound function symbol is now `=>`.
Parameter lists in function definitions must now be wrapped in parentheses.
Added property soaking, with the `?.` operator.
Made parentheses optional, when invoking functions with arguments.
Removed the obsolete block literal syntax.

```
releaseHeader('2010-01-17', '0.2.6', '0.2.5')
```

Added Python-style chained comparisons, the conditional existence operator `?=`, and some examples from _Beautiful Code_. Bugfixes relating to statement-to-expression conversion, arguments-to-array conversion, and the TextMate syntax highlighter.

```
releaseHeader('2010-01-13', '0.2.5', '0.2.4')
```

The conditions in switch statements can now take multiple values at once — If any of them are true, the case will run. Added the long arrow `==>`, which defines and immediately binds a function to `this`. While loops can now be used as expressions, in the same way that comprehensions can. Splats can be used within pattern matches to soak up the rest of an array.

```
releaseHeader('2010-01-12', '0.2.4', '0.2.3')
```

Added ECMAScript Harmony style destructuring assignment, for dealing with extracting values from nested arrays and objects. Added indentation-sensitive heredocs for nicely formatted strings or chunks of code.

```
releaseHeader('2010-01-11', '0.2.3', '0.2.2')
```

Axed the unsatisfactory `ino` keyword, replacing it with `of` for object comprehensions. They now look like: `for prop, value of object`.

```
releaseHeader('2010-01-10', '0.2.2', '0.2.1')
```

When performing a comprehension over an object, use `ino`, instead of `in`, which helps us generate smaller, more efficient code at compile time.
Added `::` as a shorthand for saying `.prototype.`
The “splat” symbol has been changed from a prefix asterisk `*`, to a postfix ellipsis `...`
Added JavaScript’s `in` operator, empty `return` statements, and empty `while` loops.
Constructor functions that start with capital letters now include a safety check to make sure that the new instance of the object is returned.
The `extends` keyword now functions identically to `goog.inherits` in Google’s Closure Library.

```
releaseHeader('2010-01-05', '0.2.1', '0.2.0')
```

Arguments objects are now converted into real arrays when referenced.

```
releaseHeader('2010-01-05', '0.2.0', '0.1.6')
```

Major release. Significant whitespace. Better statement-to-expression conversion. Splats. Splice literals. Object comprehensions. Blocks. The existential operator. Many thanks to all the folks who posted issues, with special thanks to [Liam O’Connor-Davis](http://github.com/liamoc) for whitespace and expression help.

```
releaseHeader('2009-12-27', '0.1.6', '0.1.5')
```

Bugfix for running `coffee --interactive` and `--run` from outside of the CoffeeScript directory. Bugfix for nested function/if-statements.

```
releaseHeader('2009-12-26', '0.1.5', '0.1.4')
```

Array slice literals and array comprehensions can now both take Ruby-style ranges to specify the start and end. JavaScript variable declaration is now pushed up to the top of the scope, making all assignment statements into expressions. You can use `\` to escape newlines. The `coffee-script` command is now called `coffee`.

```
releaseHeader('2009-12-25', '0.1.4', '0.1.3')
```

The official CoffeeScript extension is now `.coffee` instead of `.cs`, which properly belongs to [C#](http://en.wikipedia.org/wiki/C_Sharp_(programming_language)). Due to popular demand, you can now also use `=` to assign. Unlike JavaScript, `=` can also be used within object literals, interchangeably with `:`. Made a grammatical fix for chained function calls like `func(1)(2)(3)(4)`. Inheritance and super no longer use `__proto__`, so they should be IE-compatible now.

```
releaseHeader('2009-12-25', '0.1.3', '0.1.2')
```

The `coffee` command now includes `--interactive`, which launches an interactive CoffeeScript session, and `--run`, which directly compiles and executes a script. Both options depend on a working installation of Narwhal. The `aint` keyword has been replaced by `isnt`, which goes together a little smoother with `is`. Quoted strings are now allowed as identifiers within object literals: eg. `{"5+5": 10}`. All assignment operators now use a colon: `+:`, `-:`, `*:`, etc.

```
releaseHeader('2009-12-24', '0.1.2', '0.1.1')
```

Fixed a bug with calling `super()` through more than one level of inheritance, with the re-addition of the `extends` keyword. Added experimental [Narwhal](http://narwhaljs.org/) support (as a Tusk package), contributed by [Tom Robinson](http://blog.tlrobinson.net/), including **bin/cs** as a CoffeeScript REPL and interpreter. New `--no-wrap` option to suppress the safety function wrapper.

```
releaseHeader('2009-12-24', '0.1.1', '0.1.0')
```

Added `instanceof` and `typeof` as operators.

```
releaseHeader('2009-12-24', '0.1.0', '8e9d637985d2dc9b44922076ad54ffef7fa8e9c2')
```

Initial CoffeeScript release.
