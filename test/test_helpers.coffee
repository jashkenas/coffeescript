{indexOf, include, starts, ends, compact, count, merge, extend, flatten, del, last} = CoffeeScript.helpers

array  = [0..4]
string = array.join ''
object = {}

# Test `indexOf`
eq 0, indexOf array, 0
eq 2, indexOf array, 2
eq 4, indexOf array, 4
eq(-1, indexOf array, 6)

# Test `include`
ok include array, 0
ok include array, 2
ok include array, 4
ok not include array, 6

# Test `starts`
ok starts string, '012'
ok starts string, '34', 3
ok not starts string, '42'
ok not starts string, '42', 6

# Test `ends`
ok ends string, '234'
ok ends string, '01', 3
ok not ends string, '42'
ok not ends string, '42', 6

# Test `merge`
merged = merge object, array
ok merged isnt object
eq merged[3], 3

# Test `extend`
ok object is extend object, array
eq object[3], 3

# Test `flatten`
eq "#{ flatten [0, [1, 2], 3, [4]] }", "#{ array }"

# Test `del`
eq 1, del object, 1
ok 1 not of object

# Test `last`
eq 4, last array
eq 2, last array, 2
