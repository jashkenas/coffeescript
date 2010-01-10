(function(){
  var __a, __b, age, ages, child, years_old;
  years_old = {
    max: 10,
    ida: 9,
    tim: 11
  };
  ages = (function() {
    __b = []; __a = years_old;
    for (child in __a) {
      age = __a[child];
      if (__a.hasOwnProperty(child)) {
        __b.push(child + " is " + age);
      }
    }
    return __b;
  })();
})();