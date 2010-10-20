var _ref, _result, globals, name;
var __hasProp = Object.prototype.hasOwnProperty;
globals = (function() {
  _result = [];
  for (name in _ref = window) {
    if (!__hasProp.call(_ref, name)) continue;
    _result.push(name);
  }
  return _result;
})().slice(0, 10);