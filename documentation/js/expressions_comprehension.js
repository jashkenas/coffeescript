var globals, name, _ref, _results;
var __hasProp = Object.prototype.hasOwnProperty;
globals = ((function() {
  _ref = window;
  _results = [];
  for (name in _ref) {
    if (!__hasProp.call(_ref, name)) continue;
    _results.push(name);
  }
  return _results;
})()).slice(0, 10);