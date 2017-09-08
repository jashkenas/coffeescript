### `let` and `const`: block-scoped and reassignment-protected variables

When CoffeeScript was designed, `var` was [intentionally omitted](https://github.com/jashkenas/coffeescript/issues/238#issuecomment-153502). This was to spare developers the mental housekeeping of needing to worry about variable _declaration_ (`var foo`) as opposed to variable _assignment_ (`foo = 1`). The CoffeeScript compiler automatically takes care of declaration for you, by generating `var` statements at the top of every function scope. This makes it impossible to accidentally declare a global variable.

`let` and `const` add a useful ability to JavaScript in that you can use them to declare variables within a _block_ scope, for example within an `if` statement body or a `for` loop body, whereas `var` always declares variables in the scope of an entire function. When CoffeeScript 2 was designed, there was much discussion of whether this functionality was useful enough to outweigh the simplicity offered by never needing to consider variable declaration in CoffeeScript. In the end, it was decided that the simplicity was more valued. In CoffeeScript there remains only one type of variable.

Keep in mind that `const` only protects you from _reassigning_ a variable; it doesn’t prevent the variable’s value from changing, the way constants usually do in other languages:

```js
const obj = {foo: 'bar'};
obj.foo = 'baz'; // Allowed!
obj = {}; // Throws error
```
