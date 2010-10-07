var _i, _len, _len2, _ref, _result, food, lunch, pos, roid, roid2;
lunch = (function() {
  _result = []; _ref = ['toast', 'cheese', 'wine'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    food = _ref[_i];
    _result.push(eat(food));
  }
  return _result;
})();
for (pos = 0, _len = asteroids.length; pos < _len; pos++) {
  roid = asteroids[pos];
  for (_i = 0, _len2 = asteroids.length; _i < _len2; _i++) {
    roid2 = asteroids[_i];
    if (roid !== roid2) {
      if (roid.overlaps(roid2)) {
        roid.explode();
      }
    }
  }
}