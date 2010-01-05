(function(){
  var __a, __b, __c, __d, __e, dozen_eggs, i;
  __d = 0;
  __e = eggs.length;
  for (__c=0, i=__d; (__d <= __e ? i < __e : i > __e); (__d <= __e ? i += 12 : i -= 12), __c++) {
    dozen_eggs = eggs.slice(i, i + 12);
    deliver(new egg_carton(dozen));
  }
})();