x: 1
y: {}
y.x: => 3

print(x is 1)
print(typeof(y.x) is 'function')
print(y.x() is 3)
print(y.x.name is 'x')