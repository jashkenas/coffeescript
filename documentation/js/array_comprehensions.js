(function(){
  var lunch;
  var a = ['toast', 'cheese', 'wine'];
  var d = [];
  for (var b=0, c=a.length; b<c; b++) {
    var food = a[b];
    d[b] = food.eat();
  }
  lunch = d;
  var e = table;
  for (var f=0, g=e.length; f<g; f++) {
    var row = e[f];
    var i = f;
    i % 2 === 0 ? highlight(row) : null;
  }
})();