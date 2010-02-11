(function(){
  var coffee, paths;
  // Quickie script to compile and run all the files given as arguments.
  process.mixin(require('sys'));
  coffee = require('./coffee-script');
  paths = process.ARGV;
  paths = paths.slice(2, paths.length);
  paths.length ? coffee.ruby_compile_files(paths, function(js) {
    return eval(js);
  }) : require('./repl');
})();