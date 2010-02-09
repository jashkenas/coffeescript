Animal: ->

Animal::move: (meters) ->
  alert @name + " moved " + meters + "m."

Snake: (name) ->
  @name: name
  this

Snake::move: ->
  alert "Slithering..."
  super 5

Snake extends Animal

Horse: (name) ->
  @name: name
  this

Horse::move: ->
  alert "Galloping..."
  super 45

Horse extends Animal

sam: new Snake "Sammy the Python"
tom: new Horse "Tommy the Palomino"

sam.move()
tom.move()




