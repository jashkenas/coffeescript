outer = ->
  inner = => Array.from arguments
  inner()

outer(1, 2)  # Returns '' in CoffeeScript 1.x, '1, 2' in CoffeeScript 2
