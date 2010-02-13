(function(){
  var Animal, Horse, Snake, __a, __b, sam, tom;
  Animal = function Animal() {  };
  Animal.prototype.move = function move(meters) {
    return alert(this.name + " moved " + meters + "m.");
  };
  Snake = function Snake(name) {
    this.name = name;
    return this;
  };
  Snake.prototype.move = function move() {
    alert("Slithering...");
    return Snake.__superClass__.move.call(this, 5);
  };
  __a = function(){};
  __a.prototype = Animal.prototype;
  Snake.__superClass__ = Animal.prototype;
  Snake.prototype = new __a();
  Snake.prototype.constructor = Snake;
  Horse = function Horse(name) {
    this.name = name;
    return this;
  };
  Horse.prototype.move = function move() {
    alert("Galloping...");
    return Horse.__superClass__.move.call(this, 45);
  };
  __b = function(){};
  __b.prototype = Animal.prototype;
  Horse.__superClass__ = Animal.prototype;
  Horse.prototype = new __b();
  Horse.prototype.constructor = Horse;
  sam = new Snake("Sammy the Python");
  tom = new Horse("Tommy the Palomino");
  sam.move();
  tom.move();
})();