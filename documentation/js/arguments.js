(function(){
  var backwards;
  backwards = function backwards() {
    arguments = Array.prototype.slice.call(arguments, 0);
    return alert(arguments.reverse());
  };
  backwards("stairway", "to", "heaven");
})();
