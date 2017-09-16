## CoffeeScript 2

### What’s New In CoffeeScript 2?

The biggest change in CoffeeScript 2 is that now the CoffeeScript compiler produces modern JavaScript syntax (ES6, or ES2015 and later). A CoffeeScript `=>` becomes a JS `=>`, a CoffeeScript `class` becomes a JS `class` and so on. Major new features in CoffeeScript 2 include [async functions](#async-functions) and [JSX](#jsx). You can read more in the [announcement](announcing-coffeescript-2/).

There are very few [breaking changes from CoffeeScript 1.x to 2](#breaking-changes); we hope the upgrade process is smooth for most projects.

### Why CoffeeScript When There’s ES6?

CoffeeScript introduced many new features to the JavaScript world, such as [`=>`](#fat-arrow) and [destructuring](#destructuring) and [classes](#classes). We are happy that ECMA has seen their utility and adopted them into ECMAScript.

CoffeeScript’s intent, however, was never to be a superset of JavaScript. One of the guiding principles of CoffeeScript has been _simplicity:_ not just removing JavaScript’s “bad parts,” but providing an elegant, concise syntax that eschews unnecessary punctuation whenever possible, to make code easier to read and reason about. This benefit of CoffeeScript remains, even in an ES2015+ world.
