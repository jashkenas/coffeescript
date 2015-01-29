perfectSquares = ->
  num = 0
  loop
    num += 1
    yield num * num
  return

window.ps or= perfectSquares()