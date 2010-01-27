(function(){
  var File, OS, Readline, checkForErrors, coffeePath;
  // This (javascript) file is generated from lib/coffee_script/narwhal/coffee-script.coffee
  // Executes the `coffee` Ruby program to convert from CoffeeScript
  // to Javascript. Eventually this will hopefully happen entirely within JS.
  // Require external dependencies.
  OS = require('os');
  File = require('file');
  Readline = require('readline');
  // The path to the CoffeeScript Compiler.
  coffeePath = File.path(module.path).dirname().dirname().dirname().dirname().dirname().join('bin', 'coffee');
  // Our general-purpose error handler.
  checkForErrors = function checkForErrors(coffeeProcess) {
    if (coffeeProcess.wait() === 0) {
      return true;
    }
    system.stderr.print(coffeeProcess.stderr.read());
    throw new Error("CoffeeScript compile error");
  };
  // Run a simple REPL, round-tripping to the CoffeeScript compiler for every
  // command.
  exports.run = function run(args) {
    var __a, __b, i, path, result;
    if (args.length) {
      __a = args;
      for (i = 0; i < __a.length; i++) {
        path = __a[i];
        exports.evalCS(File.read(path));
        delete args[i];
      }
      return true;
    }
    __b = [];
    while (true) {
      __b.push((function() {
        try {
          system.stdout.write('coffee> ').flush();
          result = exports.evalCS(Readline.readline(), ['--globals']);
          if (result !== undefined) {
            return print(result);
          }
        } catch (e) {
          return print(e);
        }
      }).call(this));
    }
    return __b;
  };
  // Compile a given CoffeeScript file into JavaScript.
  exports.compileFile = function compileFile(path) {
    var coffee;
    coffee = OS.popen([coffeePath, "--print", "--no-wrap", path]);
    checkForErrors(coffee);
    return coffee.stdout.read();
  };
  // Compile a string of CoffeeScript into JavaScript.
  exports.compile = function compile(source, flags) {
    var coffee;
    coffee = OS.popen([coffeePath, "--eval", "--no-wrap"].concat(flags || []));
    coffee.stdin.write(source).flush().close();
    checkForErrors(coffee);
    return coffee.stdout.read();
  };
  // Evaluating a string of CoffeeScript first compiles it externally.
  exports.evalCS = function evalCS(source, flags) {
    return eval(exports.compile(source, flags));
  };
  // Make a factory for the CoffeeScript environment.
  exports.makeNarwhalFactory = function makeNarwhalFactory(path) {
    var code, factoryText;
    code = exports.compileFile(path);
    factoryText = "function(require,exports,module,system,print){" + code + "/**/\n}";
    if (system.engine === "rhino") {
      return Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(global, factoryText, path, 0, null);
    } else {
      // eval requires parentheses, but parentheses break compileFunction.
      return eval("(" + factoryText + ")");
    }
  };
})();