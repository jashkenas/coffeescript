(function(){

  // Eat lunch.
  var lunch;
  var __a = ['toast', 'cheese', 'wine'];
  var __d = [];
  for (var __b=0, __c=__a.length; __b<__c; __b++) {
    var food = __a[__b];
    __d[__b] = food.eat();
  }
  lunch = __d;
  // Zebra-stripe a table.
  var __e = table;
  for (var __f=0, __g=__e.length; __f<__g; __f++) {
    var row = __e[__f];
    var i = __f;
    i % 2 === 0 ? highlight(row) : null;
  }
})();