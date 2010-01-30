(function(){
  var compiler, path, sys;
  // Executes the `coffee` Ruby program to convert from CoffeeScript to JavaScript.
  sys = require('sys');
  path = require('path');
  // The path to the CoffeeScript executable.
  compiler = path.normalize(path.dirname(__filename) + '/../../bin/coffee');
  // Compile a string over stdin, with global variables, for the REPL.
  exports.compile = function compile(code, callback) {
    var coffee, js;
    js = '';
    coffee = process.createChildProcess(compiler, ['--eval', '--no-wrap', '--globals']);
    coffee.addListener('output', function(results) {
      if ((typeof results !== "undefined" && results !== null)) {
        return js += results;
      }
    });
    coffee.addListener('exit', function() {
      return callback(js);
    });
    coffee.write(code);
    return coffee.close();
  };
  // Compile a list of CoffeeScript files on disk.
  exports.compile_files = function compile_files(paths, callback) {
    var coffee, exit_ran, js;
    js = '';
    coffee = process.createChildProcess(compiler, ['--print'].concat(paths));
    coffee.addListener('output', function(results) {
      if ((typeof results !== "undefined" && results !== null)) {
        return js += results;
      }
    });
    // NB: we have to add a mutex to make sure it doesn't get called twice.
    exit_ran = false;
    return coffee.addListener('exit', function() {
      if (exit_ran) {
        return null;
      }
      exit_ran = true;
      return callback(js);
    });
  };
})();