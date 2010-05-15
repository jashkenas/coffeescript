(function(){
  var Animal, Horse, Snake, sam, tom;
  var __extends = function(child, parent) {
    var ctor = function(){ };
    ctor.prototype = parent.prototype;
    child.__superClass__ = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
  };
  Animal = function() {  };
  Animal.prototype.move = function(meters) {
    return alert(this.name + " moved " + meters + "m.");
  };

  Snake = function(name) {
    this.name = name;
    return this;
  };
  __extends(Snake, Animal);
  Snake.prototype.move = function() {
    alert("Slithering...");
    return Snake.__superClass__.move.call(this, 5);
  };

  Horse = function(name) {
    this.name = name;
    return this;
  };
  __extends(Horse, Animal);
  Horse.prototype.move = function() {
    alert("Galloping...");
    return Horse.__superClass__.move.call(this, 45);
  };

  sam = new Snake("Sammy the Python");
  tom = new Horse("Tommy the Palomino");
  sam.move();
  tom.move();
})();
