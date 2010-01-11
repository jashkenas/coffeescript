(function(){
  var __a, __b, __c, __d, __e, __f, __g, food, lunch, roid, roid2;
  // Eat lunch.
  lunch = (function() {
    __a = []; __b = ['toast', 'cheese', 'wine'];
    for (__c=0; __c<__b.length; __c++) {
      food = __b[__c];
      __a.push(eat(food));
    }
    return __a;
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