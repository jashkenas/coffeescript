(function(){
  var coffee, paths;
  coffee = require('./coffee-script');
  process.mixin(require('sys'));
  paths = process.ARGV;
  paths = paths.slice(2, paths.length);
  coffee.compile_files(paths, function(js) {
    return eval(js);
  });
})();