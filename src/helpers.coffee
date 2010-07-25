# This file contains the common helper functions that we'd like to share among
# the **Lexer**, **Rewriter**, and the **Nodes**. Merge objects, flatten
# arrays, count characters, that sort of thing.

# Set up exported variables for both **Node.js** and the browser.
this.exports = this unless process?
helpers = exports.helpers = {}

# Cross-browser indexOf, so that IE can join the party.
helpers.indexOf = indexOf = (array, item, from) ->
  return array.indexOf item, from if array.indexOf
  for other, index in array
    if other is item and (not from or (from <= index))
      return index
  -1

# Does a list include a value?
helpers.include = include = (list, value) ->
  indexOf(list, value) >= 0

# Peek at the beginning of a given string to see if it matches a sequence.
helpers.starts = starts = (string, literal, start) ->
  string.substring(start, (start or 0) + literal.length) is literal

# Peek at the end of a given string to see if it matches a sequence.
helpers.ends = ends = (string, literal, back) ->
  start = string.length - literal.length - (back ? 0)
  string.substring(start, start + literal.length) is literal

# Trim out all falsy values from an array.
helpers.compact = compact = (array) -> item for item in array when item

# Count the number of occurences of a character in a string.
helpers.count = count = (string, letter) ->
  num = 0
  pos = indexOf string, letter
  while pos isnt -1
    num += 1
    pos = indexOf string, letter, pos + 1
  num

# Merge objects, returning a fresh copy with attributes from both sides.
# Used every time `BaseNode#compile` is called, to allow properties in the
# options hash to propagate down the tree without polluting other branches.
helpers.merge = merge = (options, overrides) ->
  fresh = {}
  (fresh[key] = val) for all key, val of options
  (fresh[key] = val) for all key, val of overrides if overrides
  fresh

# Extend a source object with the properties of another object (shallow copy).
# We use this to simulate Node's deprecated `process.mixin`
helpers.extend = extend = (object, properties) ->
  (object[key] = val) for all key, val of properties

# Return a completely flattened version of an array. Handy for getting a
# list of `children` from the nodes.
helpers.flatten = flatten = (array) ->
  memo = []
  for item in array
    if item instanceof Array then memo = memo.concat(item) else memo.push(item)
  memo

# Delete a key from an object, returning the value. Useful when a node is
# looking for a particular method in an options hash.
helpers.del = del = (obj, key) ->
  val = obj[key]
  delete obj[key]
  val
