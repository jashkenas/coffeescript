(function(){
  var _a, _b, _c, _d, cubed_list, list, math, num, number, opposite_day, race, square;
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
    runners = Array.prototype.slice.call(arguments, 1, arguments.length - 0);
    return print(winner, runners);
  };
  // Existence:
  if ((typeof elvis !== "undefined" && elvis !== null)) {
    alert("I knew it!");
  }
  // Array comprehensions:
  cubed_list = (function() {
    _a = []; _b = list;
    for (_c = 0, _d = _b.length; _c < _d; _c++) {
      num = _b[_c];
      _a.push(math.cube(num));
    }
    return _a;
  }).call(this);
})();
