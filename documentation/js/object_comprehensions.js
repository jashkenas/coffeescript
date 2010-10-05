var _result, age, ages, child, yearsOld;
var __hasProp = Object.prototype.hasOwnProperty;
yearsOld = {
  max: 10,
  ida: 9,
  tim: 11
};
ages = (function() {
  _result = [];
  for (child in yearsOld) {
    if (!__hasProp.call(yearsOld, child)) continue;
    age = yearsOld[child];
    _result.push(child + " is " + age);
  }
  return _result;
})();