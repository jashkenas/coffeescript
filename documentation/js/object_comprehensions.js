(function(){
  var __a, __b, age, ages, child, years_old;
  var __hasProp = Object.prototype.hasOwnProperty;
  years_old = {
    max: 10,
    ida: 9,
    tim: 11
  };
  ages = (function() {
    __a = []; __b = years_old;
    for (child in __b) {
      age = __b[child];
      if (__hasProp.call(__b, child)) {
        __a.push(child + " is " + age);
      }
    }
    return __a;
  }).call(this);
})();