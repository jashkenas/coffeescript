a: 5
atype: typeof a

b: "hello"
btype: typeof b

Klass: => .
k: new Klass()

print(atype is 'number' and btype is 'string' and k instanceof Klass)