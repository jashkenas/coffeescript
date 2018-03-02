## Contributing

Contributions are welcome! Feel free to fork [the repo](https://github.com/jashkenas/coffeescript) and submit a pull request.

[Some features of ECMAScript are intentionally unsupported](#unsupported). Please review both the open and closed [issues on GitHub](https://github.com/jashkenas/coffeescript/issues) to see if the feature you’re looking for has already been discussed. As a general rule, we don’t support ECMAScript syntax for features that aren’t yet finalized (at Stage 4 in the proposal approval process).

For more resources on adding to CoffeeScript, please see [the Wiki](https://github.com/jashkenas/coffeescript/wiki/%5BHowto%5D-Hacking-on-the-CoffeeScript-Compiler), especially [How The Parser Works](https://github.com/jashkenas/coffeescript/wiki/%5BHowTo%5D-How-parsing-works).

There are several things you can do to increase your odds of having your pull request accepted:

  * Create tests! Any pull request should probably include basic tests to verify you didn’t break anything, or future changes won’t break your code.
  * Follow the style of the rest of the CoffeeScript codebase.
  * Ensure any ECMAScript syntax is mature (at Stage 4), with no further potential changes.
  * Add only features that have broad utility, rather than a feature aimed at a specific use case or framework.

Of course, it’s entirely possible that you have a great addition, but it doesn’t fit within these constraints. Feel free to roll your own solution; you will have [plenty of company](https://github.com/jashkenas/coffeescript/wiki/In-The-Wild).
