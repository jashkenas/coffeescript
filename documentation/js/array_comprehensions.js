(function(){
  var __a, __b, __c, __d, __e, __f, __g, food, i, lunch, row;
  // Eat lunch.
  __a = ['toast', 'cheese', 'wine'];
  __c = [];
  for (__b in __a) {
    if (__a.hasOwnProperty(__b)) {
      food = __a[__b];
      __d = this.eat(food);
      __c.push(__d);
    }
  }
  lunch = __c;
  // Zebra-stripe a table.
  __e = table;
  __f = [];
  for (i in __e) {
    if (__e.hasOwnProperty(i)) {
      row = __e[i];
      i % 2 === 0 ? highlight(row) : null;
    }
  }
  __f;
})();