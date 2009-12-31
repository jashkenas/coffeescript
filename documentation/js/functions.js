(function(){
  var cube, square;
  square = function square(x) {
    return x * x;
  };
  cube = function cube(x) {
    return square(x) * x;
  };
})();