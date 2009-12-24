(function(){
  var result;
  try {
    result = nonexistent * missing;
  } catch (error) {
    result = true;
  }
  print(result);
})();