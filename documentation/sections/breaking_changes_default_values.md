### Default values for function parameters and destructured elements

Per the [ES2015 spec regarding function default parameters](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/Default_parameters) and [destructuring default values](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment#Default_values), default values are only applied when a value is missing or `undefined`. In CoffeeScript 1.x, the default value would be applied in those cases but also if the  value was `null`.

```
codeFor('breaking_change_function_parameter_default_values', 'f(null)')
```

```
codeFor('breaking_change_destructuring_default_values', 'a')
```
