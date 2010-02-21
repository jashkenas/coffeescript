(function(){
  var _a, _b, _c, _d, _e, _f, _g, food, lunch, roid, roid2;
  // Eat lunch.
  lunch = (function() {
    _a = []; _b = ['toast', 'cheese', 'wine'];
    for (_c = 0; _c < _b.length; _c++) {
      food = _b[_c];
      _a.push(eat(food));
    }
    return _a;
  }).call(this);
  // Naive collision detection.
  _d = asteroids;
  for (_e = 0; _e < _d.length; _e++) {
    roid = _d[_e];
    _f = asteroids;
    for (_g = 0; _g < _f.length; _g++) {
      roid2 = _f[_g];
      if (roid !== roid2) {
        if (roid.overlaps(roid2)) {
          roid.explode();
        }
      }
    }
  }
})();