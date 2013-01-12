translate = ({x, y}, dx, dy) ->
  x: x + dx
  y: y + dy

shirePosition =
  x: 12
  y: 19

mordorPosition = translate shirePosition, 200, 0