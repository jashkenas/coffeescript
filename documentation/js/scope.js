(function(){
  var change_numbers, new_num, num;
  num = 1;
  change_numbers = function change_numbers() {
    var new_num;
    num = 2;
    return (new_num = 3);
  };
  new_num = change_numbers();
})();