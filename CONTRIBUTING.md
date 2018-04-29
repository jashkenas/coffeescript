## How to contribute to CoffeeScript

* Before you open a ticket or send a pull request, [search](https://github.com/jashkenas/coffeescript/issues) for previous discussions about the same feature or issue. Add to the earlier ticket if you find one.

* Before sending a pull request for a feature, be sure to have [tests](https://github.com/jashkenas/coffeescript/tree/master/test).

* Use the same coding style as the rest of the [codebase](https://github.com/jashkenas/coffeescript/tree/master/src). If you’re just getting started with CoffeeScript, there’s a nice [style guide](https://github.com/polarmobile/coffeescript-style-guide).

* In your pull request, do not add documentation to `index.html` or re-build the minified `coffeescript.js` file. We’ll do those things before cutting a new release. You _should,_ however, commit the updated compiled JavaScript files in `lib`.

* To get started, read the guides in the wiki:
	* [Hacking on the CoffeeScript Compiler](https://github.com/jashkenas/coffeescript/wiki/%5BHowTo%5D-Hacking-on-the-CoffeeScript-Compiler)
	* [How parsing works](https://github.com/jashkenas/coffeescript/wiki/%5BHowTo%5D-How-parsing-works)
	* [Update the docs](https://github.com/jashkenas/coffeescript/wiki/%5BHowTo%5D-Update-the-docs)
