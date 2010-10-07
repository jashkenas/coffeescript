# This file contains the common helper functions that we'd like to share among
# the **Lexer**, **Rewriter**, and the **Nodes**. Merge objects, flatten
# arrays, count characters, that sort of thing.

# Cross-engine `indexOf`, so that JScript can join the party. Use SpiderMonkey's
# functional-style `indexOf`, if it's available.
indexOf = exports.indexOf = Array.indexOf or
  if Array::indexOf
    (array, item, from) -> array.indexOf item, from
  else
    (array, item, from) ->
      for other, index in array
        if other is item and (not from or from <= index)
          return index
      -1

# Does a list include a value?
exports.include = (list, value) ->
  indexOf(list, value) >= 0

# Peek at the beginning of a given string to see if it matches a sequence.
exports.starts = (string, literal, start) ->
  literal is string.substr start, literal.length

# Peek at the end of a given string to see if it matches a sequence.
exports.ends = (string, literal, back) ->
  len = literal.length
  literal is string.substr string.length - len - (back or 0), len

# Trim out all falsy values from an array.
exports.compact = (array) ->
  item for item in array when item

# Count the number of occurences of a character in a string.
exports.count = (string, letter) ->
  num = pos = 0
  num++ while pos = 1 + string.indexOf letter, pos
  num

# Merge objects, returning a fresh copy with attributes from both sides.
# Used every time `Base#compile` is called, to allow properties in the
# options hash to propagate down the tree without polluting other branches.
exports.merge = (options, overrides) ->
  extend (extend {}, options), overrides

# Extend a source object with the properties of another object (shallow copy).
# We use this to simulate Node's deprecated `process.mixin`.
extend = exports.extend = (object, properties) ->
  for all key, val of properties
    object[key] = val
  object

# Return a flattened version of an array.
# Handy for getting a list of `children` from the nodes.
exports.flatten = flatten = (array) ->
  flattened = []
  for element in array
    if element instanceof Array
      flattened = flattened.concat flatten element
    else
      flattened.push element
  flattened

# Delete a key from an object, returning the value. Useful when a node is
# looking for a particular method in an options hash.
exports.del = (obj, key) ->
  val =  obj[key]
  delete obj[key]
  val

# Gets the last item of an array(-like) object.
exports.last = (array, back) -> array[array.length - (back or 0) - 1]
