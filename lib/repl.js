(function() {
  var CoffeeScript, helpers, readline, repl, run, stdio;
  CoffeeScript = require('./coffee-script');
  helpers = require('./helpers');
  readline = require('readline');
  stdio = process.openStdin();
  helpers.extend(global, {
    quit: function() {
      return process.exit(0);
    }
  });
  run = function(buffer) {
    var val;
    try {
      val = CoffeeScript.eval(buffer.toString(), {
        bare: true,
        globals: true,
        fileName: 'repl'
      });
      if (val !== undefined) {
        puts(inspect(val));
      }
    } catch (err) {
      puts(err.stack || err.toString());
    }
    return repl.prompt();
  };
  repl = readline.createInterface(stdio);
  repl.setPrompt('coffee> ');
  stdio.on('data', function(buffer) {
    return repl.write(buffer);
  });
  repl.on('close', function() {
    return stdio.destroy();
  });
  repl.on('line', run);
  repl.prompt();
}).call(this);
