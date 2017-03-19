## get and set
Get and set are intentionally not implemented as keywords in CoffeeScript.

This is by design. While using get/set is still possible, CoffeeScript considers them anti-patterns.  

In ECMAScript these convenience function decorators were introduced for very specific uses with the browser DOM.  

If you are still convinced you need to use `get`/`set`, here are some workarounds:

* Use a [Proxy object](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy). Also see an [example of using Proxy](https://nemisj.com/why-getterssetters-is-a-bad-idea-in-javascript/). 
* Add them direcly [the long way round](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty).   