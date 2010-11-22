var globals, name, _results;
var __hasProp = Object.prototype.hasOwnProperty;
globals = (function() {
  _results = [];
  for (name in window) {
    if (!__hasProp.call(window, name)) continue;
    _results.push(name);
  }
  return _results;
}()).slice(0, 10);