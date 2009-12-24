(function(){
  var num = 10;
  var result;
  if (num === 5) {
    result = false;
  } else if (num === 'a') {
    result = false;
  } else if (num === 10) {
    result = true;
  } else if (num === 11) {
    result = false;
  } else {
    result = false;
  }
  print(result);
})();