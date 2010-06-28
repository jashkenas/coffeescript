(function(){
  task('test', 'run each of the unit tests', function() {
    var _a, _b, _c, _d;
    _a = []; _c = files;
    for (_b = 0, _d = _c.length; _b < _d; _b++) {
      (function() {
        var test = _c[_b];
        return _a.push(fs.readFile(test, function(err, code) {
          return eval(coffee.compile(code));
        }));
      })();
    }
    return _a;
  });
})();
