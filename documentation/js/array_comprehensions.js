var _i, _j, _len, _len2, _len3, _ref, _result, food, index, lunch, roid, roid2;
lunch = (function() {
  _result = []; _ref = ['toast', 'cheese', 'wine'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    food = _ref[_i];
    _result.push(eat(food));
  }
  return _result;
})();
for (index = 0, _len2 = asteroids.length; index < _len2; index++) {
  roid = asteroids[index];
  for (_j = 0, _len3 = asteroids.length; _j < _len3; _j++) {
    roid2 = asteroids[_j];
    if (roid !== roid2) {
      if (roid.overlaps(roid2)) {
        roid.explode();
      }
    }
  }
}