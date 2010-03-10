# This file contains the common helper functions that we'd like to share among
# the **Lexer**, **Rewriter**, and the **Nodes**. Merge objects, flatten
# arrays, count characters, that sort of thing.

# Set up exported variables for both **Node.js** and the browser.
this.exports: this unless process?

# Does a list include a value?
exports.include: include: (list, value) ->
  list.indexOf(value) >= 0

# Peek at the beginning of a given string to see if it matches a sequence.
exports.starts: starts: (string, literal, start) ->
  string.substring(start, (start or 0) + literal.length) is literal

# Trim out all falsy values from an array.
exports.compact: compact: (array) -> item for item in array when item

# Count the number of occurences of a character in a string.
exports.count: count: (string, letter) ->
  num: 0
  pos: string.indexOf(letter)
  while pos isnt -1
    num += 1
    pos: string.indexOf(letter, pos + 1)
  num

# Merge objects, returning a fresh copy with attributes from both sides.
# Used every time `BaseNode#compile` is called, to allow properties in the
# options hash to propagate down the tree without polluting other branches.
exports.merge: merge: (options, overrides) ->
  fresh: {}
  (fresh[key]: val) for key, val of options
  (fresh[key]: val) for key, val of overrides if overrides
  fresh

# Return a completely flattened version of an array. Handy for getting a
# list of `children` from the nodes.
exports.flatten: flatten: (array) ->
  memo: []
  for item in array
    if item instanceof Array then memo: memo.concat(item) else memo.push(item)
  memo

# Delete a key from an object, returning the value. Useful when a node is
# looking for a particular method in an options hash.
exports.del: del: (obj, key) ->
  val: obj[key]
  delete obj[key]
  val

# Matches a balanced group such as a single or double-quoted string. Pass in
# a series of delimiters, all of which must be nested correctly within the
# contents of the string. This method allows us to have strings within
# interpolations within strings, ad infinitum.
exports.balanced_string: balanced_string: (str, delimited, options) ->
  options ||= {}
  slash: delimited[0][0] is '/'
  levels: []
  i: 0
  while i < str.length
    if levels.length and starts str, '\\', i
      i += 1
    else
      for pair in delimited
        [open, close]: pair
        if levels.length and starts(str, close, i) and levels[levels.length - 1] is pair
          levels.pop()
          i += close.length - 1
          i += 1 unless levels.length
          break
        else if starts str, open, i
          levels.push(pair)
          i += open.length - 1
          break
    break if not levels.length or slash and starts str, '\n', i
    i += 1
  if levels.length
    return false if slash
    throw new Error "SyntaxError: Unterminated ${levels.pop()[0]} starting on line ${@line + 1}"
  if not i then false else str.substring(0, i)