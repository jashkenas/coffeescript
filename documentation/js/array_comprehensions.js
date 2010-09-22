var _i, _j, _len, _len2, _ref, _ref2, _result, food, lunch, roid, roid2;
lunch = (function() {
  _result = []; _ref = ['toast', 'cheese', 'wine'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    food = _ref[_i];
    _result.push(eat(food));
  }
  return _result;
})();
_ref = asteroids;
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  roid = _ref[_i];
  _ref2 = asteroids;
  for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
    roid2 = _ref2[_j];
    if (roid !== roid2) {
      if (roid.overlaps(roid2)) {
        roid.explode();
      }
    }
  }
}