## The Existential Operator

It’s a little difficult to check for the existence of a variable in JavaScript. `if (variable) …` comes close, but fails for zero, the empty string, and false. CoffeeScript’s existential operator `?` returns true unless a variable is **null** or **undefined**, which makes it analogous to Ruby’s `nil?`

It can also be used for safer conditional assignment than `||=` provides, for cases where you may be handling numbers or strings.

```
codeFor('existence', 'footprints')
```

The accessor variant of the existential operator `?.` can be used to soak up null references in a chain of properties. Use it instead of the dot accessor `.` in cases where the base value may be **null** or **undefined**. If all of the properties exist then you’ll get the expected result, if the chain is broken, **undefined** is returned instead of the **TypeError** that would be raised otherwise.

```
codeFor('soaks')
```

Soaking up nulls is similar to Ruby’s [andand gem](https://rubygems.org/gems/andand), and to the [safe navigation operator](http://docs.groovy-lang.org/latest/html/documentation/index.html#_safe_navigation_operator) in Groovy.
