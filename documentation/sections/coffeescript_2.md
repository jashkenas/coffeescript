## CoffeeScript 2

### What’s New In CoffeeScript 2?

The biggest change in CoffeeScript 2 is that now the CoffeeScript compiler produces modern, ES2015+ JavaScript. A CoffeeScript `=>` becomes an ES `=>`, a CoffeeScript `class` becomes an ES `class` and so on. With the exception of [modules](#modules) (`import` and `export` statements) and [JSX](#jsx), all the ES2015+ features that CoffeeScript supports can run natively in Node 7.6+, meaning that Node can run CoffeeScript’s output without any further processing required. You can [run the tests in your browser](http://coffeescript.org/v<%= majorVersion %>/test.html) to see if your browser can do the same; Chrome has supported all features since version 55.

Support for ES2015+ syntax is important to ensure compatibility with frameworks that assume ES2015. Now that CoffeeScript compiles classes to the ES `class` keyword, it’s possible to `extend` an ES class; that wasn’t possible in CoffeeScript 1. Parity in how language features work is also important on its own; CoffeeScript “is just JavaScript,” and so things like [function parameter default values](#breaking-changes-default-values) should behave the same in CoffeeScript as in JavaScript.

Many ES2015+ features have been backported to CoffeeScript 1.11 and 1.12, including [modules](#modules), [`for…of`](#generator-iteration), and [tagged template literals](#tagged-template-literals). Major new features unique to CoffeeScript 2 are support for ES2017’s [async functions](#async-functions) and for [JSX](#jsx). More details are in the [changelog](#changelog).

There are very few [breaking changes from CoffeeScript 1.x to 2](#breaking-changes); we hope the upgrade process is smooth for most projects.

### Why CoffeeScript When There’s ES2015?

CoffeeScript introduced many new features to the JavaScript world, such as [`=>`](#fat-arrow) and [destructuring](#destructuring) and [classes](#classes). We are happy that ECMA has seen their utility and adopted them into ECMAScript.

CoffeeScript’s intent, however, was never to be a superset of JavaScript. One of the guiding principles of CoffeeScript has been _simplicity:_ not just removing JavaScript’s “bad parts,” but providing an elegant, concise syntax that eschews unnecessary punctuation whenever possible, to make code easier to read and reason about. This benefit of CoffeeScript remains, even in an ES2015 world.
