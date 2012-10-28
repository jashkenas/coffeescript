class Query
  constructor: (q) -> @els = document.querySelectorAll q
  bind: (event, fun) -> el.addEventListener(event, fun) for el in @els
  click: @bind('click', ...)