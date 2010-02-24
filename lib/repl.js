(function(){
  var coffee, prompt, quit, readline;
  // A CoffeeScript port/version of the Node.js REPL.
  // Required modules.
  coffee = require('coffee-script');
  // Shortcut variables.
  prompt = 'coffee> ';
  quit = function quit() {
    return process.exit(0);
  };
  // The main REPL function. Called everytime a line of code is entered.
  // Attempt to evaluate the command. If there's an exception, print it.
  readline = function readline(code) {
    var val;
    try {
      val = eval(coffee.compile(code, {
        no_wrap: true,
        globals: true
      }));
      if (val !== undefined) {
        p(val);
      }
    } catch (err) {
      puts(err.stack || err.toString());
    }
    return print(prompt);
  };
  // Start up the REPL.
  process.stdio.addListener('data', readline);
  process.stdio.open();
  print(prompt);
})();
