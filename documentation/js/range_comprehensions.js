(function(){
  var __a, __b, __c, __d, __e, countdown, egg_delivery, num;
  countdown = (function() {
    __a = []; __d = 10; __e = 1;
    for (__c=0, num=__d; (__d <= __e ? num <= __e : num >= __e); (__d <= __e ? num += 1 : num -= 1), __c++) {
      __a.push(num);
    }
    return __a;
  })();
  egg_delivery = function egg_delivery() {
    var __f, __g, __h, __i, __j, dozen_eggs, i;
    __f = []; __i = 0; __j = eggs.length;
    for (__h=0, i=__i; (__i <= __j ? i < __j : i > __j); (__i <= __j ? i += 12 : i -= 12), __h++) {
      __f.push((function() {
        dozen_eggs = eggs.slice(i, i + 12);
        return deliver(new egg_carton(dozen));
      })());
    }
    return __f;
  };
})();