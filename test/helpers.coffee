# Helpers
# -------

# pull the helpers from `CoffeeScript.helpers` into local variables
{starts, ends, compact, count, merge, extend, flatten, del, last} = CoffeeScript.helpers


# `starts`

test "the `starts` helper tests if a string starts with another string", ->
  ok     starts('01234', '012')
  ok not starts('01234', '123')

test "the `starts` helper can take an optional offset", ->
  ok     starts('01234', '34', 3)
  ok not starts('01234', '01', 1)


# `ends`

test "the `ends` helper tests if a string ends with another string", ->
  ok     ends('01234', '234')
  ok not ends('01234', '012')

test "the `ends` helper can take an optional offset", ->
  ok     ends('01234', '012', 2)
  ok not ends('01234', '234', 6)


# `compact`

test "the `compact` helper removes falsey values from an array, preserves truthy ones", ->
  allValues = [1, 0, false, obj={}, [], '', ' ', -1, null, undefined, true]
  truthyValues = [1, obj, [], ' ', -1, true]
  arrayEq truthyValues, compact(allValues)


# `count`

test "the `count` helper counts the number of occurances of a string in another string", ->
  eq 1/0, count('abc', '')
  eq 0, count('abc', 'z')
  eq 1, count('abc', 'a')
  eq 1, count('abc', 'b')
  eq 2, count('abcdc', 'c')
  eq 2, count('abcdabcd','abc')


# `merge`

test "the `merge` helper makes a new object with all properties of the objects given as its arguments", ->
  ary = [0, 1, 2, 3, 4]
  obj = {}
  merged = merge obj, ary
  ok merged isnt obj
  ok merged isnt ary
  for own key, val of ary
    eq val, merged[key]


# `extend`

test "the `extend` helper performs a shallow copy", ->
  ary = [0, 1, 2, 3]
  obj = {}
  # should return the object being extended
  eq obj, extend(obj, ary)
  # should copy the other object's properties as well (obviously)
  eq 2, obj[2]


# `flatten`

test "the `flatten` helper flattens an array", ->
  success = yes
  (success and= typeof n is 'number') for n in flatten [0, [[[1]], 2], 3, [4]]
  ok success


# `del`

test "the `del` helper deletes a property from an object and returns the deleted value", ->
  obj = [0, 1, 2]
  eq 1, del(obj, 1)
  ok 1 not of obj


# `last`

test "the `last` helper returns the last item of an array-like object", ->
  ary = [0, 1, 2, 3, 4]
  eq 4, last(ary)

test "the `last` helper allows one to specify an optional offset", ->
  ary = [0, 1, 2, 3, 4]
  eq 2, last(ary, 2)
