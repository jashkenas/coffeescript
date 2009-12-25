(function(){

  // This (javascript) file is generated from lib/coffee_script/narwhal/coffee-script.cs Executes the `coffee-script` Ruby program to convert from CoffeeScript
  // to Javascript. Eventually this will hopefully happen entirely within JS. Require external dependencies.
  var OS = require('os');
  var File = require('file');
  var Readline = require('readline');
  // The path to the CoffeeScript Compiler.
  var coffeePath = File.path(module.path).dirname().dirname().dirname().dirname().dirname().join('bin', 'coffee-script');
  // Our general-purpose error handler.
  var checkForErrors = function(coffeeProcess) {
    if (coffeeProcess.wait() === 0) {
      return true;
    }
    system.stderr.print(coffeeProcess.stderr.read());
    throw new Error("coffee-script compile error");
  };
  // Run a simple REPL, round-tripping to the CoffeeScript compiler for every
  // command.
  exports.run = function(args) {
    args.shift();
    if (args.length) {
      return require(File.absolute(args[0]));
    }
    while (true) {
      try {
        system.stdout.write('cs> ').flush();
        var result = exports.evalCS(Readline.readline());
        if (result !== undefined) {
          print(result);
        }
      } catch (e) {
        print(e);
      }
    }
  };
  // Compile a given CoffeeScript file into JavaScript.
  exports.compileFile = function(path) {
    var coffee = OS.popen([coffeePath, "--print", "--no-wrap", path]);
    checkForErrors(coffee);
    return coffee.stdout.read();
  };
  // Compile a string of CoffeeScript into JavaScript.
  exports.compile = function(source) {
    var coffee = OS.popen([coffeePath, "--eval", "--no-wrap"]);
    coffee.stdin.write(source).flush().close();
    checkForErrors(coffee);
    return coffee.stdout.read();
  };
  // Evaluating a string of CoffeeScript first compiles it externally.
  exports.evalCS = function(source) {
    return eval(exports.compile(source));
  };
  // Make a factory for the CoffeeScript environment.
  exports.makeNarwhalFactory = function(path) {
    var code = exports.compileFile(path);
    var factoryText = "function(require,exports,module,system,print){" + code + "/**/\n}";
    if (system.engine === "rhino") {
      return Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(global, factoryText, path, 0, null);
    } else {
      // eval requires parenthesis, but parenthesis break compileFunction.
      return eval("(" + factoryText + ")");
    }
  };
})();