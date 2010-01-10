(function(){
  var __a, __b, __c, __d, dozen_eggs;
  __c = 0; __d = eggs.length;
  for (__b=0, i=__c; (__c <= __d ? i < __d : i > __d); (__c <= __d ? i += 12 : i -= 12), __b++) {
    dozen_eggs = eggs.slice(i, i + 12);
    deliver(new egg_carton(dozen));
  }
})();