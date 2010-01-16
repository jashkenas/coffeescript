x: 1
y: {}
y.x: => 3

print(x is 1)
print(typeof(y.x) is 'function')
print(y.x() is 3)
print(y.x.name is 'x')


# The empty function should not cause a syntax error.
=>


obj: {
  name: "Fred"

  bound: =>
    (==> print(this.name is "Fred"))()

  unbound: =>
    (=> print(!this.name?))()
}

obj.unbound()
obj.bound()
