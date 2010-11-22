var food, lunch, pos, roid, roid2, _i, _j, _len, _len2, _len3, _ref;
_ref = ['toast', 'cheese', 'wine'];
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  food = _ref[_i];
  lunch = eat(food);
}
for (pos = 0, _len2 = asteroids.length; pos < _len2; pos++) {
  roid = asteroids[pos];
  for (_j = 0, _len3 = asteroids.length; _j < _len3; _j++) {
    roid2 = asteroids[_j];
    if (roid !== roid2) {
      if (roid.overlaps(roid2)) {
        roid.explode();
      }
    }
  }
}