## Unsupported ES5+ Functionality

Currently there is a fair part of the Ecmascript ecosystem that isn't directly supported. 

The following list of usupported features is incomplete but covers the most common cases: 

  * let / const
  * get / set
  * annotations
  * type annotations
  * new.target
  * generator comprehensions

**Help!** I am missing XX or XX()!  I totally need YY! 

If there is a core part of Ecmascript you think we are missing, head on over to [CS6 Discussions on Github](https://github.com/coffeescript6/discuss/), and dig around in the open and closed issues.  More than likely you will find the rational for not implementing a ES5+ feature.  It's possible that x or y feature was simply not brought up.  However more likely it's not implemented because of one of the following reasons: 

  * You haven't issued a pull request for it yet!
  * Patience young padowan! It was a lower priority and will likely be added by the community.
  * It isn't actually a ratified ES language feature, and will likely change. 
  * It falls into one of the Douglas Crockford "Bad Parts" categories.
  * It is an anti-pattern, or use of that feature would encourage poor style.
  * The feature just wouldn't add enough value to CoffeeScript.

There are a few things you should know about CoffeeScript and in particular CoffeeScript2.

CoffeeScript is about: 

  * Reducing complexity
  * Clean code
  * Being Terse
  * Removing as many "Bad Parts" as possible
  * Reducing code quality issues
  * Increasing readability
  * Being stable
  * Bringing out the best from Ecmascript

CS is NOT about: 

  * Having the latest XX/YY feature
  * Implementing every aspect of ES, just because it's there
  * Trying to appease developers from other languages

## Alternatives 

Alternate ways of accomplishing a particular feature more than likely exist.   

annotations and type annotations - [Use functional programming techniques](https://github.com/coffeescript6/discuss/issues/9#issuecomment-235975114) 

get / set - Use a [Proxy object](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy). Also see an [Example of using Proxy](https://nemisj.com/why-getterssetters-is-a-bad-idea-in-javascript/).  If you would like to dig in to the decision you can go to the [discussion on why you should avoid get/set](https://github.com/coffeescript6/discuss/issues/17#issuecomment-286652640), or if you really must, how to [add them the long way round](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty).    

## Roll Your Own 

You are of course, welcome to fork the language and add in the features you want.  There are quite a few really interesting projects that have done so, and more are totally welcome.  