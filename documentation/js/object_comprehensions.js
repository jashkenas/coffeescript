var age, ages, child, yearsOld, _results;
var __hasProp = Object.prototype.hasOwnProperty;
yearsOld = {
  max: 10,
  ida: 9,
  tim: 11
};
ages = (function() {
  _results = [];
  for (child in yearsOld) {
    if (!__hasProp.call(yearsOld, child)) continue;
    age = yearsOld[child];
    _results.push(child + " is " + age);
  }
  return _results;
})();