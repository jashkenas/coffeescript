array: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

a: array[7..9]
b: array[2...4]

result: a.concat(b).join(' ')

ok result is "7 8 9 2 3"


countdown: [10..1].join(' ')
ok countdown is "10 9 8 7 6 5 4 3 2 1"


array: [(1+5)..1+9]
ok array.join(' ') is "6 7 8 9 10"


hello: "Hello World"

ok hello[...] is "Hello World"
ok hello[1..] is "ello World"
ok hello[6..] is "World"
ok hello[6..-1] is "World"
ok hello[6...-1] is "Worl"
ok hello[1...1] is ""
ok hello[1..1] is "e"
ok hello[1...5] is "ello"
ok hello[0..4] is "Hello"
ok hello[...-1] is "Hello Worl"
ok hello[...-6] is "Hello"
ok hello[..1000] is "Hello World"

# http://wiki.ecmascript.org/doku.php?id=proposals:slice_syntax
s: "hello, world"
ok s[3...5] is 'lo'
ok s[10..] is 'ld'

a: [0, 1, 2, 3, 4, 5, 6, 7]
deepEqual a[2...6], [2, 3, 4, 5]
deepEqual a[-6...-2], [2, 3, 4, 5]
deepEqual a[...2], [0, 1]

# http://techearth.net/python/index.php5?title=Python:Basics:Slices
alphabet: 'abcdefghij'
ok alphabet[1...3] is 'bc'
ok alphabet[...3] is 'abc'
ok alphabet[1..] is 'bcdefghij'
ok alphabet[...] is 'abcdefghij'
ok alphabet[-1..] is 'j'
ok alphabet[...-1] is 'abcdefghi'

lstFruit: ['apple', 'banana', 'cherry', 'date']
deepEqual lstFruit[1...3], ['banana', 'cherry']
lstFruit2: lstFruit[...]
deepEqual lstFruit2, lstFruit
lstFruit[1]: 'blueberry'
deepEqual lstFruit2, ['apple', 'banana', 'cherry', 'date']
