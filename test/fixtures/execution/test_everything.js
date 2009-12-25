(function(){
  var func = function() {
    var a = 3;
    var b = [];
    while (a >= 0) {
      b.push('o');
      a--;
    }
    var c = {
      "text": b
    };
    if (!(42 > 41)) {
      c = 'error';
    }
    c.text = false ? 'error' : c.text + '---';
    var d = c.text.split('');
    var g = [];
    for (var e=0, f=d.length; e<f; e++) {
      var let = d[e];
      if (let === '-') {
        c.list = g.push(let);
      }
    }
    c.list = g;
    c.single = c.list.slice(1, 1 + 1)[0];
    return c.single;
  };
  print(func() === '-');
})();