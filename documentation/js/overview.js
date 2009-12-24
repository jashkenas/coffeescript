(function(){

  // Assignment:
  var number = 42;
  var opposite_day = true;
  // Conditions:
  if (opposite_day) {
    number = -42;
  }
  // Functions:
  var square = function(x) {
    return x * x;
  };
  // Arrays:
  var list = [1, 2, 3, 4, 5];
  // Objects:
  var math = {
    root: Math.sqrt,
    square: square,
    cube: function(x) {
      return x * square(x);
    }
  };
  // Array comprehensions:
  var cubed_list;
  var a = list;
  var d = [];
  for (var b=0, c=a.length; b<c; b++) {
    var num = a[b];
    d[b] = math.cube(num);
  }
  cubed_list = d;
})();