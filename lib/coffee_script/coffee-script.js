(function(){
  var sys;
  // Executes the `coffee` Ruby program to convert from CoffeeScript to JavaScript.
  sys = require('sys');
  exports.compile = function compile(code, callback) {
    var coffee, js;
    js = '';
    coffee = process.createChildProcess('coffee', ['--eval', '--no-wrap', '--globals']);
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
})();