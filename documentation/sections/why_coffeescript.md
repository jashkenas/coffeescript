## Why CoffeeScript?
There are a few things you should know about CoffeeScript. 

CoffeeScript is about: 

  * Reducing complexity
  * Keeping your code clean
  * Being terse
  * Removing as many 'Bad Parts' as possible
  * Reducing code quality issues
  * Increasing readability
  * Being stable
  * Bringing out the best from ECMAScript

CoffeeScript is NOT about: 

  * Having the latest XX/YY feature
  * Implementing every aspect of ECMAScript, just because it's there.
  * Trying to appease developers from other languages

There are many style choices within the language, and they have been carefully thought out.  Taking time out to understand how CoffeeScript works, and how to work well with it will help you write better, easier to read, safer and more reliable code.

There are many benefits  as ? and significant whitespace, and how such features help improve readability and reduce bugs.

## Why not just use ECMAScript 7?

ECMAScript has adopted much of the syntax and ideas of CoffeeScript, however it still exposes you to many of the 'Bad Parts' of the language. In addition, being able to use terse syntax and significant whitespace means your code is still easier to maintain and read.

Code written with CoffeeScript 
CoffeeScript doesn't have the issue of accidental global varibles.  We generate scoped variables no matter what.
We have an operator that checks existence `?`
CoffeeScript is fully interoperable with ECMAScript code.