(function(){
  var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, food, lunch, roid, roid2;
  // Eat lunch.
  lunch = (function() {
    _a = []; _b = ['toast', 'cheese', 'wine'];
    for (_c = 0, _d = _b.length; _c < _d; _c++) {
      food = _b[_c];
      _a.push(eat(food));
    }
    return _a;
  }).call(this);
  // Naive collision detection.
  _e = asteroids;
  for (_f = 0, _g = _e.length; _f < _g; _f++) {
    roid = _e[_f];
    _h = asteroids;
    for (_i = 0, _j = _h.length; _i < _j; _i++) {
      roid2 = _h[_i];
      if (roid !== roid2) {
        if (roid.overlaps(roid2)) {
          roid.explode();
        }
      }
    }
  }
})();
