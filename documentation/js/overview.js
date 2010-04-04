(function(){
  var _a, _b, _c, _d, cubed_list, list, math, num, number, opposite_day, race, square;
  var __slice = Array.prototype.slice;
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
    runners = __slice.call(arguments, 1, arguments.length - 0);
    return print(winner, runners);
  };
  // Existence:
  if ((typeof elvis !== "undefined" && elvis !== null)) {
    alert("I knew it!");
  }
  // Array comprehensions:
  cubed_list = (function() {
    _a = []; _c = list;
    for (_b = 0, _d = _c.length; _b < _d; _b++) {
      num = _c[_b];
      _a.push(math.cube(num));
    }
    return _a;
  }).call(this);
})();
