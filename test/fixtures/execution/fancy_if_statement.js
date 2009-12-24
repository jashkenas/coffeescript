(function(){
  var a = b = d = true;
  var c = false;
  var result = a ? b ? c ? false : d ? true : null : null : null;
  print(result);
})();