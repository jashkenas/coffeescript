(function(){
  var File, OS, Readline, checkForErrors, coffeePath;
  // This (javascript) file is generated from lib/coffee_script/narwhal/coffee-script.coffee Executes the `coffee` Ruby program to convert from CoffeeScript
  // to Javascript. Eventually this will hopefully happen entirely within JS. Require external dependencies.
  OS = require('os');
  File = require('file');
  Readline = require('readline');
  // The path to the CoffeeScript Compiler.
  coffeePath = File.path(module.path).dirname().dirname().dirname().dirname().dirname().join('bin', 'coffee');
  // Our general-purpose error handler.
  checkForErrors = function(coffeeProcess) {
    if (coffeeProcess.wait() === 0) {
      return true;
    }
    system.stderr.print(coffeeProcess.stderr.read());
    throw new Error("CoffeeScript compile error");
  };
  // Run a simple REPL, round-tripping to the CoffeeScript compiler for every
  // command.
  exports.run = function(args) {
    var __a, __b, __c, __d, path, result;
    if (args.length) {
      __a = args;
      __d = [];
      for (__b=0, __c=__a.length; __b<__c; __b++) {
        path = __a[__b];
        __d[__b] = exports.evalCS(File.read(path));
      }
      __d;
      return true;
    }
    while (true) {
      try {
        system.stdout.write('coffee> ').flush();
        result = exports.evalCS(Readline.readline());
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
    var coffee;
    coffee = OS.popen([coffeePath, "--print", "--no-wrap", path]);
    checkForErrors(coffee);
    return coffee.stdout.read();
  };
  // Compile a string of CoffeeScript into JavaScript.
  exports.compile = function(source) {
    var coffee;
    coffee = OS.popen([coffeePath, "--eval", "--no-wrap"]);
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