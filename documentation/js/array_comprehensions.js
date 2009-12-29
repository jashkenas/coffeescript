(function(){
  var __a, __b, __c, __d, __e, __f, __g, __h, food, i, lunch, row;
  // Eat lunch.
  __a = ['toast', 'cheese', 'wine'];
  __d = [];
  for (__b=0, __c=__a.length; __b<__c; __b++) {
    food = __a[__b];
    __d[__b] = food.eat();
  }
  lunch = __d;
  // Zebra-stripe a table.
  __e = table;
  __h = [];
  for (__f=0, __g=__e.length; __f<__g; __f++) {
    row = __e[__f];
    i = __f;
    __h[__f] = i % 2 === 0 ? highlight(row) : null;
  }
  __h;
})();