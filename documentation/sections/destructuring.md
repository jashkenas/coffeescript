## Destructuring Assignment

Just like JavaScript (since ES2015), CoffeeScript has destructuring assignment syntax. When you assign an array or object literal to a value, CoffeeScript breaks up and matches both sides against each other, assigning the values on the right to the variables on the left. In the simplest case, it can be used for parallel assignment:

```
codeFor('parallel_assignment', 'theBait')
```

But it’s also helpful for dealing with functions that return multiple values.

```
codeFor('multiple_return_values', 'forecast')
```

Destructuring assignment can be used with any depth of array and object nesting, to help pull out deeply nested properties.

```
codeFor('object_extraction', 'name + "-" + street')
```

Destructuring assignment can even be combined with splats.

```
codeFor('patterns_and_splats', 'contents.join("")')
```

Expansion can be used to retrieve elements from the end of an array without having to assign the rest of its values. It works in function parameter lists as well.

```
codeFor('expansion', 'first + " " + last')
```

Destructuring assignment is also useful when combined with class constructors to assign properties to your instance from an options object passed to the constructor.

```
codeFor('constructor_destructuring', 'tim.age + " " + tim.height')
```

The above example also demonstrates that if properties are missing in the destructured object or array, you can, just like in JavaScript, provide defaults. Note though that unlike with the existential operator, the default is only applied with the value is missing or `undefined`—[passing `null` will set a value of `null`](#breaking-changes-default-values), not the default.
