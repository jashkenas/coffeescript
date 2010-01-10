(function(){
  var __a, __b, __c, __d, __e, __f, __g, lunch;
  // Eat lunch.
  lunch = (function() {
    __c = []; __a = ['toast', 'cheese', 'wine'];
    for (__b=0; __b<__a.length; __b++) {
      food = __a[__b];
      __c.push(eat(food));
    }
    return __c;
  })();
  // Naive collision detection.
  __d = asteroids;
  for (__e=0; __e<__d.length; __e++) {
    roid = __d[__e];
    __f = asteroids;
    for (__g=0; __g<__f.length; __g++) {
      roid2 = __f[__g];
      if (roid !== roid2) {
        if (roid.overlaps(roid2)) {
          roid.explode();
        }
      }
    }
  }
})();