## Browser-based Tests

CoffeeScript includes an extensive test suite, which verifies that the compiler generates JavaScript that behaves as it should. The tests canonically run via the Node runtime, and must all pass there before we consider publishing a new release of CoffeeScript; but you can also run the tests in a web browser. This can be a good way to determine which features of CoffeeScript your current browser may not support. In general, the latest version of [Google Chrome Canary](https://www.google.com/chrome/browser/canary.html) should pass all the tests.

Note that since no JavaScript runtime yet supports ES2015 modules, the tests for module support verify only that the CoffeeScript compiler’s output is the correct syntax; the tests don’t verify that the modules resolve properly.

[Run the tests in your browser.](test.html)
