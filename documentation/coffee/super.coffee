Animal: =>
Animal.prototype.move: meters =>
  alert(this.name + " moved " + meters + "m.")

Snake: name => this.name: name
Snake extends Animal
Snake.prototype.move: =>
  alert("Slithering...")
  super(5)

Horse: name => this.name: name
Horse extends Animal
Horse.prototype.move: =>
  alert("Galloping...")
  super(45)

sam: new Snake("Sammy the Python")
tom: new Horse("Tommy the Palomino")

sam.move()
tom.move()




