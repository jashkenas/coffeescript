var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, food, lunch, roid, roid2;
lunch = (function() {
  _a = []; _c = ['toast', 'cheese', 'wine'];
  for (_b = 0, _d = _c.length; _b < _d; _b++) {
    food = _c[_b];
    _a.push(eat(food));
  }
  return _a;
})();
_f = asteroids;
for (_e = 0, _g = _f.length; _e < _g; _e++) {
  roid = _f[_e];
  _i = asteroids;
  for (_h = 0, _j = _i.length; _h < _j; _h++) {
    roid2 = _i[_h];
    if (roid !== roid2) {
      if (roid.overlaps(roid2)) {
        roid.explode();
      }
    }
  }
}