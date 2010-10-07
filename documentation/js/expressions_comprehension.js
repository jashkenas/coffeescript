var _result, globals, name;
var __hasProp = Object.prototype.hasOwnProperty;
globals = (function() {
  _result = [];
  for (name in window) {
    if (!__hasProp.call(window, name)) continue;
    _result.push(name);
  }
  return _result;
})().slice(0, 10);