(function() {
  var CoffeeScript, error, helpers, readline, repl, run, stdin, stdout;
  CoffeeScript = require('./coffee-script');
  helpers = require('./helpers');
  readline = require('readline');
  stdin = process.openStdin();
  stdout = process.stdout;
  error = function(err) {
    return stdout.write((err.stack || err.toString()) + '\n\n');
  };
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
        filename: 'repl'
      });
      if (val !== void 0) {
        process.stdout.write(val + '\n');
      }
    } catch (err) {
      error(err);
    }
    return repl.prompt();
  };
  process.on('uncaughtException', error);
  if (readline.createInterface.length < 3) {
    repl = readline.createInterface(stdin);
    stdin.on('data', function(buffer) {
      return repl.write(buffer);
    });
  } else {
    repl = readline.createInterface(stdin, stdout);
  }
  repl.setPrompt('coffee> ');
  repl.on('close', function() {
    return stdin.destroy();
  });
  repl.on('line', run);
  repl.prompt();
}).call(this);
