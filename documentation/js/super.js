(function(){
  var Animal = function() {
  };
  Animal.prototype.move = function(meters) {
    return alert(this.name + " moved " + meters + "m.");
  };
  var Snake = function(name) {
    this.name = name;
    return this.name;
  };
  Snake.prototype.__proto__ = new Animal();
  Snake.prototype.move = function() {
    alert("Slithering...");
    return Snake.prototype.__proto__.move.call(this, 5);
  };
  var Horse = function(name) {
    this.name = name;
    return this.name;
  };
  Horse.prototype.__proto__ = new Animal();
  Horse.prototype.move = function() {
    alert("Galloping...");
    return Horse.prototype.__proto__.move.call(this, 45);
  };
  var sam = new Snake("Sammy the Python");
  var tom = new Horse("Tommy the Palomino");
  sam.move();
  tom.move();
})();