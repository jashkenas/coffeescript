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
  var __a = list;
  var __d = [];
  for (var __b=0, __c=__a.length; __b<__c; __b++) {
    var num = __a[__b];
    __d[__b] = math.cube(num);
  }
  cubed_list = __d;
})();