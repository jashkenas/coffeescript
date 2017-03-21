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

There are many style choices within the language, and they have been carefully thought out. Taking time out to understand how CoffeeScript works, and how to work well with it will help you write better, easier to read, safer and more reliable code.

## Why not just use ECMAScript 7?


ECMAScript has adopted much of the syntax and ideas of CoffeeScript. Unfortunately it still exposes you to many of the 'Bad Parts' of the language. On top of that the ECMASCript syntax is cumulative, allowing a much larger spectrum of potential errors. 

ECMAScript 6/7 are standards, and you should probably know how to work with it. You might assume that working with ECMAScript 6 is more direct or cleaner. But using those newer features still requires a transpiler, for instance Babel. If you consider most front end targetted code still needs a build tool like Grunt, then you will find adding an extra step for CoffeeScript very trivial. 

You will find:

* CoffeeScript has adopted the vast majority of stable ECMAScript features.
* CoffeeScript protects you by avoiding a wide spectrum of errors. 
* You have consistent variable behavior without having to think about context and usage of every variable.
* You reduce cognitive load of the syntax and can get down to solving problems.
* Most parentheses are optional, making functional programming styles much cleaner.
* CoffeeScript forces indenting, which makes code much more readable, and eliminates many nesting errors.
* Most Parentheses go away and no more semicolan errors.  
* CoffeeScript has an existential operator `?`, which makes checking for missing elements a breeze.
* CoffeeScript is fully interoperable with ECMAScript code.
* Cleaner syntax for yields, async, and unbound functions `() ->` 

You can learn CoffeeScript in a few hours, and you will be amazed at how much better your code will be.