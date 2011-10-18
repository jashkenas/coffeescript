(function() {
  var key, val, _ref;

  _ref = require('./coffee-script');
  for (key in _ref) {
    if (!(key in _ref)) continue;
    val = _ref[key];
    exports[key] = val;
  }

}).call(this);
