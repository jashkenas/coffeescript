# test
f1: (x) =>
  x * x
  f2: (y) =>
    y * x
  f3: 3

# Parens can close on the proper level.
elements.each((el) =>
  el.click((event) =>
    el.reset()
    el.show() if event.active
  )
)

# Or, parens can close blocks early.
elements.each((el) =>
  el.click((event) =>
    el.reset()
    el.show() if event.active))