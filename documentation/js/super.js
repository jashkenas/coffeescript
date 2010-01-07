(function(){
  var Animal, Horse, Snake, sam, tom;
  Animal = function Animal() {
  };
  Animal.prototype.move = function move(meters) {
    return alert(this.name + " moved " + meters + "m.");
  };
  Snake = function Snake(name) {
    var __a;
    __a = this.name = name;
    return Snake === this.constructor ? this : __a;
  };
  Snake.__superClass__ = Animal.prototype;
  Snake.prototype = new Animal();
  Snake.prototype.constructor = Snake;
  Snake.prototype.move = function move() {
    alert("Slithering...");
    return Snake.__superClass__.move.call(this, 5);
  };
  Horse = function Horse(name) {
    var __a;
    __a = this.name = name;
    return Horse === this.constructor ? this : __a;
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