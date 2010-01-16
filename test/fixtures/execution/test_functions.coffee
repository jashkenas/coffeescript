x: 1
y: {}
y.x: => 3

print(x is 1)
print(typeof(y.x) is 'function')
print(y.x() is 3)
print(y.x.name is 'x')


obj: {
  name: "Fred"

  bound: =>
    (==> print(this.name is "Fred"))()

  unbound: =>
    (=> print(!this.name?))()
}

obj.unbound()
obj.bound()


# When when a closure wrapper is generated for expression conversion, make sure
# that references to "this" within the wrapper are safely converted as well.

obj: {
  num: 5
  func: =>
    this.result: if false
      10
    else
      "a"
      "b"
      this.num
}

print(obj.num is obj.func())
print(obj.num is obj.result)