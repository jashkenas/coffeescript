(function(){
  var num = 1;
  var change_numbers = function() {
    num = 2;
    var new_num = 3;
    return new_num;
  };
  var new_num = change_numbers();
})();