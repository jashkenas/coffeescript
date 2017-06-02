## The Existential Operator

It’s a little difficult to check for the existence of a variable in JavaScript. `if (variable) …` comes close, but fails for zero, the empty string, and false (to name just the most common cases). CoffeeScript’s existential operator `?` returns true unless a variable is `null` or `undefined` or undeclared, which makes it analogous to Ruby’s `nil?`.

It can also be used for safer conditional assignment than the JavaScript pattern `a = a || value` provides, for cases where you may be handling numbers or strings.

```
codeFor('existence', 'footprints')
```

Note that if the compiler knows that `a` is in scope and therefore declared, `a?` compiles to `a != null`, _not_ `a !== null`. The `!=` makes a loose comparison to `null`, which does double duty also comparing against `undefined`. The reverse also holds for `not a?` or `unless a?`.

```
codeFor('existence_declared')
```

If a variable might be undeclared, the compiler does a thorough check. This is what JavaScript coders _should_ be typing when they want to check if a mystery variable exists.

```
codeFor('existence_undeclared')
```

The accessor variant of the existential operator `?.` can be used to soak up null references in a chain of properties. Use it instead of the dot accessor `.` in cases where the base value may be `null` or `undefined`. If all of the properties exist then you’ll get the expected result, if the chain is broken, `undefined` is returned instead of the `TypeError` that would be raised otherwise.

```
codeFor('soaks')
```

For completeness:

| Example | Definition |
| --- | --- |
| `a?` | tests that `a` is in scope and `a != null` |
| `a ? b` | returns `a` if `a` is in scope and `a != null`; otherwise, `b` |
| `a?.b` or `a?['b']` | returns `a.b` if `a` is in scope and `a != null`; otherwise, `undefined` |
| `a?(b, c)` or `a? b, c`&emsp; | returns the result of calling `a` (with arguments `b` and `c`) if `a` is in scope and callable; otherwise, `undefined` |
| `a ?= b` | assigns the value of `b` to `a` if `a` is not in scope or if `a == null`; produces the new value of `a` |