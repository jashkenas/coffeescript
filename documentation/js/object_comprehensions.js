var _a, _b, age, ages, child, yearsOld;
var __hasProp = Object.prototype.hasOwnProperty;
yearsOld = {
  max: 10,
  ida: 9,
  tim: 11
};
ages = (function() {
  _a = []; _b = yearsOld;
  for (child in _b) {
    if (!__hasProp.call(_b, child)) continue;
    age = _b[child];
    _a.push(child + " is " + age);
  }
  return _a;
})();