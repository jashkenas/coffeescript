(function(){
  var Animal, Horse, Snake, sam, tom;
  Animal = function Animal() {
  };
  Animal.prototype.move = function move(meters) {
    return alert(this.name + " moved " + meters + "m.");
  };
  Snake = function Snake(name) {
    return this.name = name;
  };
  Snake.__superClass__ = Animal.prototype;
  Snake.prototype = new Animal();
  Snake.prototype.constructor = Snake;
  Snake.prototype.move = function move() {
    alert("Slithering...");
    return Snake.__superClass__.move.call(this, 5);
  };
  Horse = function Horse(name) {
    return this.name = name;
  };
  Horse.__superClass__ = Animal.prototype;
  Horse.prototype = new Animal();
  Horse.prototype.constructor = Horse;
  Horse.prototype.move = function move() {
    alert("Galloping...");
    return Horse.__superClass__.move.call(this, 45);
  };
  sam = new Snake("Sammy the Python");
  tom = new Horse("Tommy the Palomino");
  sam.move();
  tom.move();
})();