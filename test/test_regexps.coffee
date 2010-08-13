# Regular expression literals.
ok 'x'.match(/x/g)
ok 'x'.match /x/g
ok 'x'.match(/x/)
ok 'x'.match /x/

ok 4 / 2 / 1 is 2

y = 4
x = 2
g = 1

ok y / x/g is 2

ok 'http://google.com'.match(/:\/\/goog/)

obj = {
  width:  -> 10
  height: -> 20
}
id = 2

ok ' '.match(/ /)[0] is ' '

regexp = / /
ok ' '.match regexp

ok (obj.width()/id - obj.height()/id) is -5
