var _a, _b, _c, _d, cubes, list, math, num, number, opposite, race, square;
var __slice = Array.prototype.slice;
number = 42;
opposite = true;
if (opposite) {
  number = -42;
}
square = function(x) {
  return x * x;
};
list = [1, 2, 3, 4, 5];
math = {
  root: Math.sqrt,
  square: square,
  cube: function(x) {
    return x * square(x);
  }
};
race = function(winner) {
  var runners;
  runners = __slice.call(arguments, 1);
  return print(winner, runners);
};
if (typeof elvis !== "undefined" && elvis !== null) {
  alert("I knew it!");
}
cubes = (function() {
  _a = []; _c = list;
  for (_b = 0, _d = _c.length; _b < _d; _b++) {
    num = _c[_b];
    _a.push(math.cube(num));
  }
  return _a;
})();