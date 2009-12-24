(function(){
  var nums;
  var a = [1, 2, 3];
  var d = [];
  for (var b=0, c=a.length; b<c; b++) {
    var n = a[b];
    if (n % 2 !== 0) {
      nums = d.push(n * n);
    }
  }
  nums = d;
  var result;
  var e = nums;
  var h = [];
  for (var f=0, g=e.length; f<g; f++) {
    n = e[f];
    h[f] = n * 2;
  }
  result = h;
  print(result.join(',') === '2,18');
})();