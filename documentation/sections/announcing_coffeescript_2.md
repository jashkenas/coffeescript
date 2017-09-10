# Announcing CoffeeScript 2

We are pleased to announce CoffeeScript 2! This new release of the CoffeeScript language and compiler aims to bring CoffeeScript into the modern JavaScript era, closing gaps in compatibility with ES2015 while preserving the clean, elegant syntax that is CoffeeScript’s hallmark. In a nutshell:

- The CoffeeScript 2 compiler now translates CoffeeScript code into ES2015+ syntax. So a CoffeeScript `=>` is now output as an ES `=>`, a CoffeeScript `class` is now output as an ES `class`, and so on. This means you may need to [pipe CoffeeScript’s output through Babel](http://coffeescript.org/v2/#es2015plus-output).
- CoffeeScript 2 adds support for ES2017’s [async functions](http://coffeescript.org/#async-functions) syntax, for the future [object destructuring](http://coffeescript.org/#destructuring) syntax, and for [JSX](http://coffeescript.org/#jsx). Some ES2015+ features, such as [modules](http://coffeescript.org/#modules) (`import` and `export` statements), [`for…of`](http://coffeescript.org/#generator-iteration), and [tagged template literals](http://coffeescript.org/#tagged-template-literals) were backported into CoffeeScript versions 1.11 and 1.12.
- All of the above was achieved with very few [breaking changes from 1.x](http://coffeescript.org/v2/#breaking-changes). Most current CoffeeScript projects should be able to upgrade with little or no refactoring necessary.

CoffeeScript 2 was developed with two primary goals: remove any incompatibilities with JavaScript that might prevent CoffeeScript from being used on a project; and preserve as much backward compatibility as possible. [Install now](http://coffeescript.org/v2/#installation): `npm install -g coffeescript@2`

## ES2015+ Output

From the beginning, CoffeeScript has been described as being “just JavaScript.” And today, JavaScript is ES2015 (well, ES2017). CoffeeScript welcomes the changes in the ES world and we’re happy to stop outputting ES3  syntax for modern CoffeeScript and ES2015+ features.

(Quick history lesson: ECMAScript is the official name of JavaScript, after the ECMA standards body that defines it. ECMAScript version 3, or ES3, was released in 1999 and is the lowest common denominator version of JavaScript that anyone today considers supporting. There was no ES4, and ES5 came out in 2009. What would’ve been ES6 was eventually released as ES2015, a change in naming meant to indicate that future versions would be released every year. When we write “ES2015+”, we mean ES2015, ES2016, ES2017 and future successors.)

Many ES2015 features, such as `=>`, were adopted directly from CoffeeScript and are one-to-one compatible, or very nearly so. This has made outputting many of CoffeeScript’s innovations into ES2015 syntax straightforward: not only does `=>` become `=>`, but `{ a } = obj` becomes `{ a } = obj`, `"a#{b}c"` becomes `` `a${b}c` `` and so on.

The following CoffeeScript features were updated in 2 to output using ES2015+ syntax (or added in 1.11–2, output using modern syntax):

- Modules
- Classes
- Async functions, a.k.a. `async`/`await`
- Bound/arrow functions
- Function default parameters
- Function splat/rest parameters
- Destructuring, for both arrays and objects
- Object rest/spread properties
- Interpolated strings/template literals (ES2015 backticked strings)
- Tagged template literals
- ES2015’s `for…of` is now available as CoffeeScript’s `for…from` (we already had a `for…of`)

Not all CoffeeScript features were adopted as is; most notably, [default values](http://coffeescript.org/v2/#breaking-changes-default-values) in ES2015 and CoffeeScript 2 are only applied when a variable is `undefined`, not `undefined` or `null` as in CoffeeScript 1; and [classes](http://coffeescript.org/v2/#breaking-changes-classes) have their own differences. See the [breaking changes](http://coffeescript.org/v2/#breaking-changes) for the fine details.

In our experience, most breaking changes are edge cases that should affect very few people, like ES2015’s [lack of an `arguments` object inside arrow functions](http://coffeescript.org/v2/#breaking-change-fat-arrow). There seem to be two breaking changes that affect a significant number of projects:

- In CoffeeScript 2, “bare” `super` (calling `super` without arguments) is now no longer allowed, and one must use `super()` or `super arguments...` instead.
- References to `this`/`@` cannot occur before a call to `super`, per the ES spec.

See the [full details](http://coffeescript.org/v2/#breaking-changes-super-extends). Either the CoffeeScript compiler or Babel will throw errors for either of these cases, so updating your code is a simple matter of fixing each instance as the compiler errors on it, until your code compiles successfully.

## Other Features

Besides supporting new ES2015+ features and outputting older CoffeeScript features in ES2015+ syntax, CoffeeScript 2 has added support for the following:

- [JSX](http://coffeescript.org/v2/#jsx)
- [Line comments](http://coffeescript.org/v2/#comments) are now output (in CoffeeScript 1 they were discarded)
- Block comments are now allowed anywhere, enabling [static type annotations](http://coffeescript.org/v2/#type-annotations) using Flow’s comment-based syntax

There are many smaller improvements as well, such as to the `coffee` command-line tool. You can read all the details in the [changelog](http://coffeescript.org/v2/#changelog) for the 2.0.0 betas.

## What About…

A few features get asked about so often that we added a section to the docs called [Unsupported ECMAScript Features](http://coffeescript.org/v2/#unsupported). These include `let` and `const`, named functions and the `get` and `set` keywords. You can read the docs for the details, but simply put: `let` and `const` and named functions aren’t necessary for compatibility or interoperability with other libraries, and supporting them would add unwanted complexity to CoffeeScript; and getters and setters are supported but with the more verbose syntax.

## Future Compatibility

Back when CoffeeScript 1 was created, [Babel](babeljs.io) and ES2015 were both several years away. The CoffeeScript compiler itself had to do what today’s Babel compiler does, converting modern features like destructuring and arrow functions into equivalent ES3 JavaScript.

But Babel exists now, and it does its one job—converting today’s and tomorrow’s JavaScript into yesterday’s—exceedingly well. With Babel around, there’s no need for the CoffeeScript compiler to duplicate its functionality. All the CoffeeScript compiler needs to worry about now is converting the CoffeeScript version of new syntax into the ES version of that syntax, e.g. `import fs from 'fs'` into `import fs from 'fs'`. The CoffeeScript compiler need not do all the work that Babel does. This makes adding support for new ES features much easier than before.

Fortunately, most features added by ECMA in recent years haven’t required any updates at all in CoffeeScript. New global objects, or methods on global objects, are just supported and output as is. Want to use `Object.assign` in CoffeeScript? Just type `Object.assign`. Ditto for `Array.forEach` and `Array.map` and `String.includes` and any number of excellent additions to the language that ECMA has added. You may need to add [polyfills](https://babeljs.io/docs/usage/polyfill/) for these methods if your target runtime(s) don’t support them, but that would be no different than if you used these methods in a plain JavaScript project.

Some proposed future ES features _do_ involve new syntax, like [class fields](https://github.com/tc39/proposal-class-fields). We have adopted a policy of supporting new syntax only when it reaches Stage 4 in ECMA’s process, which means that the syntax is final and will be in the next ES release. On occasion we might support a _feature_ before it has reached Stage 4, but output it using ES2015 syntax instead of the newly-proposed syntax; that’s what’s happening in 2.0.0 for [object destructuring](http://coffeescript.org/v2/#splats), where our output uses the same polyfill that Babel uses. When the new syntax is finalized, we will update our output to use the final syntax.

## Credits

The major features of 2.0.0 would not have been possible without the following people:

- [@GeoffreyBooth](https://github.com/GeoffreyBooth): Organizer of the CoffeeScript 2 effort, developer for modules; arrow functions, function default parameters and function rest parameters output using ES2015 syntax; line comments output and block comments output anywhere; block embedded JavaScript via triple backticks; improved parsing of Literate CoffeeScript; and the new docs website.
- [@connec](https://github.com/connec): Classes; destructuring; splats/rest syntax in arrays and function calls; and computed properties all output using ES2015 syntax.
- [@GabrielRatener](https://github.com/GabrielRatener): Async functions.
- [@xixixao](https://github.com/xixixao): JSX.
- [@zdenko](https://github.com/zdenko): Object rest/spread properties (object destructuring).
- [@greghuc](https://github.com/greghuc): Tagged template literals, interpolated strings output in ES2015 syntax.
- [@atg](https://github.com/atg): ES2015 `for…of`, supported as CoffeeScript’s `for…from`.
- [@lydell](https://github.com/lydell) and [@jashkenas](https://github.com/jashkenas): Guidance, code reviews and feedback.


See the full [honor roll](https://github.com/jashkenas/coffeescript/wiki/CoffeeScript-2-Honor-Roll).

Thanks and we hope you enjoy CoffeeScript 2!