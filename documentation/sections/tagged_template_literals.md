## Tagged Template Literals

CoffeeScript supports [ES2015 tagged template literals](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Template_literals#Tagged_template_literals), which enable customized string interpolation. If you immediately prefix a string with a function name (no space between the two), CoffeeScript will output this “function plus string” combination as an ES2015 tagged template literal, which will [behave accordingly](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Template_literals#Tagged_template_literals): the function is called, with the parameters being the input text and expression parts that make up the interpolated string. The function can then assemble these parts into an output string, providing custom string interpolation.

Be aware that the CoffeeScript compiler is outputting ES2015 syntax for this feature, so your target JavaScript runtime(s) must support this syntax for your code to work; or you could use tools like [Babel](http://babeljs.io/) or [Traceur Compiler](https://github.com/google/traceur-compiler) to convert this ES2015 syntax into compatible JavaScript.

```
codeFor('tagged_template_literals', 'greet("greg", "awesome")')
```
