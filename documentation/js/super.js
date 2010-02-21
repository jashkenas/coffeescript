(function(){
  var Animal, Horse, Snake, _a, _b, sam, tom;
  Animal = function Animal() {  };
  Animal.prototype.move = function move(meters) {
    return alert(this.name + " moved " + meters + "m.");
  };
  Snake = function Snake(name) {
    this.name = name;
    return this;
  };
  _a = function(){};
  _a.prototype = Animal.prototype;
  Snake.__superClass__ = Animal.prototype;
  Snake.prototype = new _a();
  Snake.prototype.constructor = Snake;
  Snake.prototype.move = function move() {
    alert("Slithering...");
    return Snake.__superClass__.move.call(this, 5);
  };
  Horse = function Horse(name) {
    this.name = name;
    return this;
  };
  _b = function(){};
  _b.prototype = Animal.prototype;
  Horse.__superClass__ = Animal.prototype;
  Horse.prototype = new _b();
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