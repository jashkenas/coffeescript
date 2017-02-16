## Lexical Scoping and Variable Safety

The CoffeeScript compiler takes care to make sure that all of your variables are properly declared within lexical scope — you never need to write `var` yourself.

```
codeFor('scope', 'inner')
```

Notice how all of the variable declarations have been pushed up to the top of the closest scope, the first time they appear. **outer** is not redeclared within the inner function, because it’s already in scope; **inner** within the function, on the other hand, should not be able to change the value of the external variable of the same name, and therefore has a declaration of its own.

This behavior is effectively identical to Ruby’s scope for local variables. Because you don’t have direct access to the `var` keyword, it’s impossible to shadow an outer variable on purpose, you may only refer to it. So be careful that you’re not reusing the name of an external variable accidentally, if you’re writing a deeply nested function.

Although suppressed within this documentation for clarity, all CoffeeScript output is wrapped in an anonymous function: `(function(){ … })();` This safety wrapper, combined with the automatic generation of the `var` keyword, make it exceedingly difficult to pollute the global namespace by accident.

If you’d like to create top-level variables for other scripts to use, attach them as properties on **window**; attach them as properties on the **exports** object in CommonJS; or use an [`export` statement](#modules). If you’re targeting both CommonJS and the browser, the **existential operator** (covered below), gives you a reliable way to figure out where to add them: `exports ? this`
