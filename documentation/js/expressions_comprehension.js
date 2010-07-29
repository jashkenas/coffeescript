var _a, _b, _c, globals, name;
var __hasProp = Object.prototype.hasOwnProperty;
globals = (function() {
  _b = []; _c = window;
  for (name in _c) {
    if (!__hasProp.call(_c, name)) continue;
    _a = _c[name];
    _b.push(name);
  }
  return _b;
})().slice(0, 10);