{ indexOf, include, starts, ends, compact, count, merge, extend, flatten, del
} = require('../lib/helpers').helpers

array = [0..4]

ok indexOf(array, 0) is 0
ok indexOf(array, 2) is 2
ok indexOf(array, 4) is 4
ok indexOf(array, 6) is -1

ok include array, 0
ok include array, 2
ok include array, 4
ok not include array, 6

string = array.join ''

ok starts string, '012'
ok starts string, '34', 3
ok not starts string, '42'
ok not starts string, '42', 6

ok ends string, '234'
ok ends string, '01', 3
ok not ends string, '42'
ok not ends string, '42', 6

object = {}
merged = merge object, array

ok merged isnt object
ok merged[3] is 3

ok object is extend object, array
ok object[3] is 3

ok "#{ flatten [0, [1, 2], 3, [4]] }" is "#{ array }"

ok 1 is del object, 1
ok 1 not of object
