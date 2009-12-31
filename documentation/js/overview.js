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
  __c = [];
  for (__b in __a) {
    if (__a.hasOwnProperty(__b)) {
      num = __a[__b];
      __d = math.cube(num);
      __c.push(__d);
    }
  }
  cubed_list = __c;
})();