(function(){
  var coffee, factories, file, loader, os, puts;
  // The Narwhal-compatibility wrapper for CoffeeScript.
  // Require external dependencies.
  os = require('os');
  file = require('file');
  coffee = require('./coffee-script');
  // Alias print to "puts", for Node.js compatibility:
  puts = print;
  // Compile a string of CoffeeScript into JavaScript.
  exports.compile = function compile(source) {
    return coffee.compile(source);
  };
  // Compile a given CoffeeScript file into JavaScript.
  exports.compileFile = function compileFile(path) {
    return coffee.compile(file.read(path));
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
  // The Narwhal loader for '.coffee' files.
  factories = {};
  loader = {};
  // Reload the coffee-script environment from source.
  loader.reload = function reload(topId, path) {
    return factories[topId] = function() {
      return exports.makeNarwhalFactory(path);
    };
  };
  // Ensure that the coffee-script environment is loaded.
  loader.load = function load(topId, path) {
    return factories[topId] = factories[topId] || this.reload(topId, path);
  };
  require.loader.loaders.unshift([".coffee", loader]);
})();
