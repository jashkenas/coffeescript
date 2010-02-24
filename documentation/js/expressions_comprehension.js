(function(){
  var _a, _b, globals, name;
  var __hasProp = Object.prototype.hasOwnProperty;
  // The first ten global properties.
  globals = (function() {
    _a = []; _b = window;
    for (name in _b) { if (__hasProp.call(_b, name)) {
      _a.push(name);
    }}
    return _a;
  }).call(this).slice(0, 10);
})();
