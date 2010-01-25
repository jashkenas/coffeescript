(function(){
  var __a, __b, __c, cubed_list, list, math, num, number, opposite_day, race, square;
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
  // Splats:
  race = function race(winner) {
    var runners;
    runners = Array.prototype.slice.call(arguments, 1);
    return print(winner, runners);
  };
  // Existence:
  if ((typeof elvis !== "undefined" && elvis !== null)) {
    alert("I knew it!");
  }
  // Array comprehensions:
  cubed_list = (function() {
    __a = []; __b = list;
    for (__c = 0; __c < __b.length; __c++) {
      num = __b[__c];
      __a.push(math.cube(num));
    }
    return __a;
  }).call(this);
})();