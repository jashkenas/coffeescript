(function(){
  var __a, __b, __c, __d, cubed_list, list, math, num, number, opposite_day, square;
  // Assignment:
  number = 42;
  opposite_day = true;
  // Conditions:
  if (opposite_day) {
    number = -42;
  }
  // Functions:
  square = function square(x) {
    return x * x;
  };
  // Arrays:
  list = [1, 2, 3, 4, 5];
  // Objects:
  math = {
    root: Math.sqrt,
    square: square,
    cube: function cube(x) {
      return x * square(x);
    }
  };
  // Array comprehensions:
  __a = list;
  __d = [];
  for (__b=0, __c=__a.length; __b<__c; __b++) {
    num = __a[__b];
    __d[__b] = math.cube(num);
  }
  cubed_list = __d;
})();