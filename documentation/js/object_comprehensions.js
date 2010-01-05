(function(){
  var __a, __b, __c, age, ages, child, years_old;
  years_old = {
    max: 10,
    ida: 9,
    tim: 11
  };
  ages = (function() {
    __a = years_old;
    __b = [];
    for (child in __a) {
      if (__a.hasOwnProperty(child)) {
        age = __a[child];
        __c = child + " is " + age;
        __b.push(__c);
      }
    }
    return __b;
  })();
})();