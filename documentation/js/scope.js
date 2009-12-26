(function(){
  var change_numbers, new_num, num;
  num = 1;
  change_numbers = function() {
    var new_num;
    num = 2;
    new_num = 3;
    return new_num;
  };
  new_num = change_numbers();
})();