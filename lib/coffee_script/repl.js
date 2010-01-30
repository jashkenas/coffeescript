(function(){
  var coffee, prompt, quit, readline, run;
  // A CoffeeScript port/version of the Node.js REPL.
  // Required modules.
  coffee = require('./coffee-script');
  process.mixin(require('sys'));
  // Shortcut variables.
  prompt = 'coffee> ';
  quit = function quit() {
    return process.stdio.close();
  };
  // The main REPL function. Called everytime a line of code is entered.
  readline = function readline(code) {
    return coffee.compile(code, run);
  };
  // Attempt to evaluate the command. If there's an exception, print it.
  run = function run(js) {
    var val;
    try {
      val = eval(js);
      if (val !== undefined) {
        p(val);
      }
    } catch (err) {
      puts(err.stack || err.toString());
    }
    return print(prompt);
  };
  // Start up the REPL.
  process.stdio.open();
  process.stdio.addListener('data', readline);
  print(prompt);
})();