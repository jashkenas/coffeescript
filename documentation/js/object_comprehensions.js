var _ref, _result, age, ages, child, yearsOld;
var __hasProp = Object.prototype.hasOwnProperty;
yearsOld = {
  max: 10,
  ida: 9,
  tim: 11
};
ages = (function() {
  _result = []; _ref = yearsOld;
  for (child in _ref) {
    if (!__hasProp.call(_ref, child)) continue;
    age = _ref[child];
    _result.push(child + " is " + age);
  }
  return _result;
})();