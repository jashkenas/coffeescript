(function(){
  var backwards;
  backwards = function backwards() {
    return alert(Array.prototype.slice.call(arguments, 0).reverse());
  };
  backwards("stairway", "to", "heaven");
})();