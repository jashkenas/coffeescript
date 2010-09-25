# This file contains the common helper functions that we'd like to share among
# the **Lexer**, **Rewriter**, and the **Nodes**. Merge objects, flatten
# arrays, count characters, that sort of thing.

helpers = exports.helpers = {}

# Cross-engine indexOf, so that JScript can join the party.
indexOf = helpers.indexOf = Array.indexOf or
  if Array::indexOf
    (array, item, from) -> array.indexOf item, from
  else
    (array, item, from) ->
      for other, index in array
        if other is item and (not from or from <= index)
          return index
      -1

# Does a list include a value?
helpers.include = (list, value) -> 0 <= indexOf list, value

# Peek at the beginning of a given string to see if it matches a sequence.
helpers.starts = (string, literal, start) ->
  literal is string.substr start, literal.length

# Peek at the end of a given string to see if it matches a sequence.
helpers.ends = (string, literal, back) ->
  ll = literal.length
  literal is string.substr string.length - ll - (back or 0), ll

# Trim out all falsy values from an array.
helpers.compact = (array) -> item for item in array when item

# Count the number of occurences of a character in a string.
helpers.count = (string, letter) ->
  num = pos = 0
  num++ while 0 < pos = 1 + string.indexOf letter, pos
  num

# Merge objects, returning a fresh copy with attributes from both sides.
# Used every time `BaseNode#compile` is called, to allow properties in the
# options hash to propagate down the tree without polluting other branches.
helpers.merge = (options, overrides) ->
  extend (extend {}, options), overrides

# Extend a source object with the properties of another object (shallow copy).
# We use this to simulate Node's deprecated `process.mixin`
extend = helpers.extend = (object, properties) ->
  (object[key] = val) for all key, val of properties
  object

# Return a flattened version of an array (nonrecursive).
# Handy for getting a list of `children` from the nodes.
helpers.flatten = (array) -> array.concat.apply [], array

# Delete a key from an object, returning the value. Useful when a node is
# looking for a particular method in an options hash.
helpers.del = (obj, key) ->
  val =  obj[key]
  delete obj[key]
  val
