(function(){
  var _a, _b, age, ages, child, years_old;
  var __hasProp = Object.prototype.hasOwnProperty;
  years_old = {
    max: 10,
    ida: 9,
    tim: 11
  };
  ages = (function() {
    _a = []; _b = years_old;
    for (child in _b) { if (__hasProp.call(_b, child)) {
      age = _b[child];
      _a.push(child + " is " + age);
    }}
    return _a;
  })();
})();
