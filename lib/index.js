(function() {
  var _cache, key, val;
  var __hasProp = Object.prototype.hasOwnProperty;
  _cache = require('./coffee-script');
  for (key in _cache) {
    if (!__hasProp.call(_cache, key)) continue;
    val = _cache[key];
    (exports[key] = val);
  }
})();
