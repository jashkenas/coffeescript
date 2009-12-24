(function(){
  var a = 5;
  var atype = typeof a;
  var b = "hello";
  var btype = typeof b;
  var Klass = function() {
  };
  var k = new Klass();
  print(atype === 'number' && btype === 'string' && k instanceof Klass);
})();