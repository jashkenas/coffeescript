## Resources

*   [Source Code](http://github.com/jashkenas/coffeescript/)<br>
    Use `bin/coffee` to test your changes,<br>
    `bin/cake test` to run the test suite,<br>
    `bin/cake build` to rebuild the CoffeeScript compiler, and<br>
    `bin/cake build:parser` to regenerate the Jison parser if you’re working on the grammar.

    `git checkout lib && bin/cake build:full` is a good command to run when you’re working on the core language. It’ll refresh the lib directory (in case you broke something), build your altered compiler, use that to rebuild itself (a good sanity test) and then run all of the tests. If they pass, there’s a good chance you’ve made a successful change.
*   [Browser Tests](v<%= majorVersion %>/test.html)<br>
    Run CoffeeScript’s test suite in your current browser.
*   [CoffeeScript Issues](http://github.com/jashkenas/coffeescript/issues)<br>
    Bug reports, feature proposals, and ideas for changes to the language belong here.
*   [CoffeeScript Google Group](https://groups.google.com/forum/#!forum/coffeescript)<br>
    If you’d like to ask a question, the mailing list is a good place to get help.
*   [The CoffeeScript Wiki](http://github.com/jashkenas/coffeescript/wiki)<br>
    If you’ve ever learned a neat CoffeeScript tip or trick, or ran into a gotcha — share it on the wiki. The wiki also serves as a directory of handy [text editor extensions](http://github.com/jashkenas/coffeescript/wiki/Text-editor-plugins), [web framework plugins](http://github.com/jashkenas/coffeescript/wiki/Web-framework-plugins), and general [CoffeeScript build tools](http://github.com/jashkenas/coffeescript/wiki/Build-tools).
*   [The FAQ](http://github.com/jashkenas/coffeescript/wiki/FAQ)<br>
    Perhaps your CoffeeScript-related question has been asked before. Check the FAQ first.
*   [JS2Coffee](http://js2coffee.org)<br>
    Is a very well done reverse JavaScript-to-CoffeeScript compiler. It’s not going to be perfect (infer what your JavaScript classes are, when you need bound functions, and so on…) — but it’s a great starting point for converting simple scripts.
*   [High-Rez Logo](https://github.com/jashkenas/coffeescript/tree/master/documentation/images)<br>
    The CoffeeScript logo is available in SVG for use in presentations.
