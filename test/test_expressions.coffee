# Ensure that we don't wrap Nodes that are "pure_statement" in a closure.

items: [1, 2, 3, "bacon", 4, 5]

for item in items
  break if item is "bacon"

findit: (items) ->
  for item in items
    return item if item is "bacon"

ok findit(items) is "bacon"


# When when a closure wrapper is generated for expression conversion, make sure
# that references to "this" within the wrapper are safely converted as well.

obj: {
  num: 5
  func: ->
    this.result: if false
      10
    else
      "a"
      "b"
      this.num
}

ok obj.num is obj.func()
ok obj.num is obj.result