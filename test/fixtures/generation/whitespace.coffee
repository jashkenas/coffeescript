# test
f1: x =>
  x * x
  f2: y =>
    y * x

elements.each(el =>
  el.click(event =>
    el.show() if event.active))