(function(){
  var __a, __b, __c, __d, __e, __f, __g, __h, __i, __j, food, lunch, roid, roid2;
  // Eat lunch.
  lunch = (function() {
    __a = ['toast', 'cheese', 'wine'];
    __c = [];
    for (__b in __a) {
      if (__a.hasOwnProperty(__b)) {
        food = __a[__b];
        __d = eat(food);
        __c.push(__d);
      }
    }
    return __c;
  })();
  // Naive collision detection.
  __e = asteroids;
  for (__f in __e) {
    if (__e.hasOwnProperty(__f)) {
      roid = __e[__f];
      __h = asteroids;
      for (__i in __h) {
        if (__h.hasOwnProperty(__i)) {
          roid2 = __h[__i];
          if (roid !== roid2) {
            if (roid.overlaps(roid2)) {
              roid.explode();
            }
          }
        }
      }
    }
  }
})();