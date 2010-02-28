class Animal
  move: (meters) ->
    alert @name + " moved " + meters + "m."

class Snake extends Animal
  constructor: (name) ->
    @name: name

  move: ->
    alert "Slithering..."
    super 5

class Horse extends Animal
  constructor: (name) ->
    @name: name

  move: ->
    alert "Galloping..."
    super 45

sam: new Snake "Sammy the Python"
tom: new Horse "Tommy the Palomino"

sam.move()
tom.move()




