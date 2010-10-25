var _i, _j, _len, _len2, _len3, _ref, _ref2, _ref3, food, lunch, pos, roid, roid2;
_ref = ['toast', 'cheese', 'wine'];
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  food = _ref[_i];
  lunch = eat(food);
}
_ref2 = asteroids;
for (pos = 0, _len2 = _ref2.length; pos < _len2; pos++) {
  roid = _ref2[pos];
  _ref3 = asteroids;
  for (_j = 0, _len3 = _ref3.length; _j < _len3; _j++) {
    roid2 = _ref3[_j];
    if (roid !== roid2) {
      if (roid.overlaps(roid2)) {
        roid.explode();
      }
    }
  }
}