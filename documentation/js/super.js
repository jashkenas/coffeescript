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
  Snake.__superClass__ = Animal.prototype;
  Snake.prototype = new Animal();
  Snake.prototype.constructor = Snake;
  Snake.prototype.move = function() {
    alert("Slithering...");
    return Snake.__superClass__.move.call(this, 5);
  };
  var Horse = function(name) {
    this.name = name;
    return this.name;
  };
  Horse.__superClass__ = Animal.prototype;
  Horse.prototype = new Animal();
  Horse.prototype.constructor = Horse;
  Horse.prototype.move = function() {
    alert("Galloping...");
    return Horse.__superClass__.move.call(this, 45);
  };
  var sam = new Snake("Sammy the Python");
  var tom = new Horse("Tommy the Palomino");
  sam.move();
  tom.move();
})();