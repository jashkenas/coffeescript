# Helpers
# -------

# pull the helpers from `CoffeeScript.helpers` into local variables
{starts, ends, compact, count, merge, extend, flatten, del, last, baseFileName, normalizePath, relativePath} = CoffeeScript.helpers


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


# `baseFileName`

test "the `baseFileName` helper returns the file name to write to", ->
  ext = '.js'
  sourceToCompiled =
    '.coffee': ext
    'a.coffee': 'a' + ext
    'b.coffee': 'b' + ext
    'coffee.coffee': 'coffee' + ext

    '.litcoffee': ext
    'a.litcoffee': 'a' + ext
    'b.litcoffee': 'b' + ext
    'coffee.litcoffee': 'coffee' + ext

    '.lit': ext
    'a.lit': 'a' + ext
    'b.lit': 'b' + ext
    'coffee.lit': 'coffee' + ext

    '.coffee.md': ext
    'a.coffee.md': 'a' + ext
    'b.coffee.md': 'b' + ext
    'coffee.coffee.md': 'coffee' + ext

  for sourceFileName, expectedFileName of sourceToCompiled
    name = baseFileName sourceFileName, yes
    filename = name + ext
    eq filename, expectedFileName


# `normalizePath`

test "various tests for normalizePath", ->
  eq "/", normalizePath "/"
  eq "", normalizePath "."
  eq "", normalizePath ""
  eq "/a/b", normalizePath "/a/b"
  eq "/a/c/", normalizePath "/a/c/"
  eq "/a/c", normalizePath "/a/c/", true
  eq "/a/d", normalizePath "/a/../a/./d/c/.."
  eq "/a/e/", normalizePath "/a/../a/./e/c/../"
  eq "/a/e", normalizePath "/a/../a/./e/c/../", true
  eq "../a", normalizePath "../a"
  eq "../b", normalizePath "a/../../b"

# `relativePath`

test "various tests for relativePath", ->
  # Same level
  eq "foo.js", relativePath "foo.coffee", "foo.js"
  eq "foo.js", relativePath "foo.coffee", "foo.js", "/work/src"
  # Same level, but both down one level
  eq "bar.js", relativePath "src/bar.coffee", "src/bar.js"
  eq "bar.js", relativePath "src/bar.coffee", "src/bar.js", "/work/src"
  # Sam level, using '.'' as from
  eq "baz.js", relativePath ".", "baz.js"
  eq "baz.js", relativePath ".", "baz.js", "/work/src"
  eq "o/qux.js", relativePath ".", "o/qux.js"
  eq "o/qux.js", relativePath ".", "o/qux.js", "/work/src"
  # Up one level
  eq "../", relativePath "src/bar.js", "."
  eq "../", relativePath "src/bar.js", ".", "/work/src"
  # Up and over one directory
  eq "../dest/foo.js", relativePath "src/foo.coffee", "dest/foo.js"
  eq "../dest/foo.js", relativePath "src/foo.coffee", "dest/foo.js", "/work/src"
  # Absolute paths
  eq "dest1/dest2/bar.js", relativePath "/bar.coffee", "/dest1/dest2/bar.js"
  # File vs. directory - keep trailing '/'
  eq "../c", relativePath "a/b/", "a/c"
  eq "../d/", relativePath "a/b/", "a/d/"
  # This should throw, since relativePath can't know the name of the directory that foo.coffee is in.
  throws -> relativePath "../o/foo.js", "foo.coffee"
  # With the CWD, this should pass.
  eq "../src/foo.coffee", relativePath "../o/foo.js", "foo.coffee", "/work/src"
