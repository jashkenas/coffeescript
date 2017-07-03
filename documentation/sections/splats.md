## Splats, or Rest Parameters/Spread Syntax

The JavaScript `arguments` object is a useful way to work with functions that accept variable numbers of arguments. CoffeeScript provides splats `...`, both for function definition as well as invocation, making variable numbers of arguments a little bit more palatable. ES2015 adopted this feature as their [rest parameters](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/rest_parameters).

```
codeFor('splats', true)
```

<div id="array-spread" class="bookmark"></div>

Splats also let us elide array elements...

```
codeFor('array_spread', 'all')
```

<div id="object-spread" class="bookmark"></div>

...and object properties.

```
codeFor('object_spread', 'JSON.stringify(currentUser)')
```

In ECMAScript this is called [spread syntax](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_operator), and has been supported for arrays since ES2015 but is [coming soon for objects](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_operator#Spread_in_object_literals). Until object spread syntax is officially supported, the CoffeeScript compiler outputs the same polyfill as [Babel’s rest spread transform](https://babeljs.io/docs/plugins/transform-object-rest-spread/); but once it is supported, we will revise the compiler’s output. Note that there are [very subtle differences](https://developers.google.com/web/updates/2017/06/object-rest-spread) between the polyfill and the current proposal.