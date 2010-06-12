(function(){
  var CoffeeScript, helpers, readline, repl, run, stdio;
  // A very simple Read-Eval-Print-Loop. Compiles one line at a time to JavaScript
  // and evaluates it. Good for simple tests, or poking around the **Node.js** API.
  // Using it looks like this:
  //     coffee> puts "$num bottles of beer" for num in [99..1]
  // Require the **coffee-script** module to get access to the compiler.
  CoffeeScript = require('./coffee-script');
  helpers = require('./helpers').helpers;
  readline = require('readline');
  // Start by opening up **stdio**.
  stdio = process.openStdin();
  // Quick alias for quitting the REPL.
  helpers.extend(global, {
    quit: function() {
      return process.exit(0);
    }
  });
  // The main REPL function. **run** is called every time a line of code is entered.
  // Attempt to evaluate the command. If there's an exception, print it out instead
  // of exiting.
  run = function(buffer) {
    var val;
    try {
      val = CoffeeScript.run(buffer.toString(), {
        noWrap: true,
        globals: true,
        source: 'repl'
      });
      if (val !== undefined) {
        puts(inspect(val));
      }
    } catch (err) {
      puts(err.stack || err.toString());
    }
    return repl.prompt();
  };
  // Create the REPL by listening to **stdin**.
  repl = readline.createInterface(stdio);
  repl.setPrompt('coffee> ');
  stdio.addListener('data', function(buffer) {
    return repl.write(buffer);
  });
  repl.addListener('close', function() {
    return stdio.destroy();
  });
  repl.addListener('line', run);
  repl.prompt();
})();
