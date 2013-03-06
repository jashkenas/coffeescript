# This file contains the common helper functions that we'd like to share among
# the **Lexer**, **Rewriter**, and the **Nodes**. Merge objects, flatten
# arrays, count characters, that sort of thing.

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

# Count the number of occurrences of a string in a string.
exports.count = (string, substr) ->
  num = pos = 0
  return 1/0 unless substr.length
  num++ while pos = 1 + string.indexOf substr, pos
  num

# Merge objects, returning a fresh copy with attributes from both sides.
# Used every time `Base#compile` is called, to allow properties in the
# options hash to propagate down the tree without polluting other branches.
exports.merge = (options, overrides) ->
  extend (extend {}, options), overrides

# Extend a source object with the properties of another object (shallow copy).
extend = exports.extend = (object, properties) ->
  for key, val of properties
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

# Typical Array::some
exports.some = Array::some ? (fn) ->
  return true for e in this when fn e
  false

# Simple function for inverting Literate CoffeeScript code by putting the
# documentation in comments, and bumping the actual code back out to the edge ...
# producing a string of CoffeeScript code that can be compiled "normally".
exports.invertLiterate = (code) ->
  lines = for line in code.split('\n')
    if match = (/^([ ]{4}|\t)/).exec line
      line[match[0].length..]
    else
      '# ' + line
  lines.join '\n'

# Merge two jison-style location data objects together.
# If `last` is not provided, this will simply return `first`.
buildLocationData = (first, last) ->
  if not last
    first
  else
    first_line: first.first_line
    first_column: first.first_column
    last_line: last.last_line
    last_column: last.last_column

# This returns a function which takes an object as a parameter, and if that object is an AST node,
# updates that object's locationData.  The object is returned either way.
exports.addLocationDataFn = (first, last) ->
    (obj) ->
      if ((typeof obj) is 'object') and (!!obj['updateLocationDataIfMissing'])
        obj.updateLocationDataIfMissing buildLocationData(first, last)

      return obj

# Convert jison location data to a string.
# `obj` can be a token, or a locationData.
exports.locationDataToString = (obj) ->
    if ("2" of obj) and ("first_line" of obj[2]) then locationData = obj[2]
    else if "first_line" of obj then locationData = obj

    if locationData
      "#{locationData.first_line + 1}:#{locationData.first_column + 1}-" +
      "#{locationData.last_line + 1}:#{locationData.last_column + 1}"
    else
      "No location data"

# A `.coffee.md` compatible version of `basename`, that returns the file sans-extension.
exports.baseFileName = (file, stripExt = no) ->
  parts = file.split('/')
  file = parts[parts.length - 1]
  return file unless stripExt
  parts = file.split('.')
  parts.pop()
  parts.pop() if parts[parts.length - 1] is 'coffee'
  parts.join('.')

# Determine if a filename represents a CoffeeScript file.
exports.isCoffee = (file) -> /\.((lit)?coffee|coffee\.md)$/.test file

# Determine if a filename represents a Literate CoffeeScript file.
exports.isLiterate = (file) -> /\.(litcoffee|coffee\.md)$/.test file


# Remove any "." components in a path, any ".."s in the middle of a path.  Leaves a trailing '/'
# if present, unless removeTrailingSlash is set.
exports.normalizePath = normalizePath = (path, removeTrailingSlash=no) ->
  root = no # Does this path start with the root?
  parts = path.split '/'
  i = 0
  # If the path started with a '/', set the root flag.
  if parts.length > 1 and parts[i] == ''
    parts.splice i, 1
    root = yes
  while i < parts.length
    if parts[i] in ['.', '']
      if (i is parts.length - 1) and not removeTrailingSlash
        # Leave the trailing '/''
        parts[i] = ''
        i++
      else
        # Remove the empty element
        parts.splice i, 1
    else if parts[i] is '..'
      if i is 0 or (i and parts[i-1] is '..')
        # Leave the ".."
        i++
      else
        # Remove the '..' and the previous element
        parts.splice i-1, 2
        i--
    else
      i++
  if root
    if parts.length == 0 then return '/'
    if parts.length[0] is '..'
      # Uhh...  This doesn't make any sense.
      throw new Error "Invalid path: #{path}"
    parts.unshift '' # Add back the leading "/"
  parts.join '/'

# Solve the relative path from `from` to `to`.
#
# This is the same as node's `path.relative()`, but can be used even if we're not running in node.
# If paths are relative (don't have a leading '/') then we assume they are both relative to to
# same working directory.
#
# If `from` is a relative path that starts with '..', then `cwd` must be provided to resolve
# parent path names.
exports.relativePath = (from, to, cwd=null) ->
  if cwd
    from = cwd + "/" + from
    to = cwd + "/" + to
  from = (normalizePath from).split '/'
  to = (normalizePath to).split '/'
  while from.length > 0 and to.length > 0 and from[0] == to[0]
    from.shift()
    to.shift()
  if from.length and from[0] is ".." then throw new Error "'cwd' must be specified if 'from' references parent directory: #{from.join '/'} -> #{to.join '/'}"
  answer = ""
  if from.length > 1 then for [0...(from.length - 1)]
    answer += "../"
  answer + "#{to.join '/'}"
