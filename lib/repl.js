(function(){
  var CoffeeScript, prompt, run;
  // A very simple Read-Eval-Print-Loop. Compiles one line at a time to JavaScript
  // and evaluates it. Good for simple tests, or poking around the **Node.js** API.
  // Using it looks like this:
  //     coffee> puts "$num bottles of beer" for num in [99..1]
  // Require the **coffee-script** module to get access to the compiler.
  CoffeeScript = require('coffee-script');
  // Our prompt.
  prompt = 'coffee> ';
  // Quick alias for quitting the REPL.
  process.mixin({
    quit: function quit() {
      return process.exit(0);
    }
  });
  // The main REPL function. **run** is called every time a line of code is entered.
  // Attempt to evaluate the command. If there's an exception, print it out instead
  // of exiting.
  run = function run(code) {
    var val;
    try {
      val = CoffeeScript.run(code, 'repl', {
        no_wrap: true,
        globals: true
      });
      if (val !== undefined) {
        p(val);
      }
    } catch (err) {
      puts(err.stack || err.toString());
    }
    return print(prompt);
  };
  // Start up the REPL by opening **stdio** and listening for input.
  process.stdio.addListener('data', run);
  process.stdio.open();
  print(prompt);
})();
