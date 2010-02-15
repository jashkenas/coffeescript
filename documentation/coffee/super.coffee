Animal: ->

Animal::move: (meters) ->
  alert @name + " moved " + meters + "m."

Snake: (name) ->
  @name: name
  this

Snake extends Animal

Snake::move: ->
  alert "Slithering..."
  super 5

Horse: (name) ->
  @name: name
  this

Horse extends Animal

Horse::move: ->
  alert "Galloping..."
  super 45

sam: new Snake "Sammy the Python"
tom: new Horse "Tommy the Palomino"

sam.move()
tom.move()




