var _i, _len, _len2, _ref, _ref2, _result, food, lunch, pos, roid, roid2;
lunch = (function() {
  _result = [];
  for (_i = 0, _len = (_ref = ['toast', 'cheese', 'wine']).length; _i < _len; _i++) {
    food = _ref[_i];
    _result.push(eat(food));
  }
  return _result;
})();
for (pos = 0, _len = (_ref = asteroids).length; pos < _len; pos++) {
  roid = _ref[pos];
  for (_i = 0, _len2 = (_ref2 = asteroids).length; _i < _len2; _i++) {
    roid2 = _ref2[_i];
    if (roid !== roid2) {
      if (roid.overlaps(roid2)) {
        roid.explode();
      }
    }
  }
}