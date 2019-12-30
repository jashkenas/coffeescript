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

# Repeat a string `n` times.
exports.repeat = repeat = (str, n) ->
  # Use clever algorithm to have O(log(n)) string concatenation operations.
  res = ''
  while n > 0
    res += str if n & 1
    n >>>= 1
    str += str
  res

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
    if '[object Array]' is Object::toString.call element
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

# Typical Array::some
exports.some = Array::some ? (fn) ->
  return true for e in this when fn e
  false

# Helper function for extracting code from Literate CoffeeScript by stripping
# out all non-code blocks, producing a string of CoffeeScript code that can
# be compiled “normally.”
exports.invertLiterate = (code) ->
  out = []
  blankLine = /^\s*$/
  indented = /^[\t ]/
  listItemStart = /// ^
    (?:\t?|\ {0,3})   # Up to one tab, or up to three spaces, or neither;
    (?:
      [\*\-\+] |      # followed by `*`, `-` or `+`;
      [0-9]{1,9}\.    # or by an integer up to 9 digits long, followed by a period;
    )
    [\ \t]            # followed by a space or a tab.
  ///
  insideComment = no
  for line in code.split('\n')
    if blankLine.test(line)
      insideComment = no
      out.push line
    else if insideComment or listItemStart.test(line)
      insideComment = yes
      out.push "# #{line}"
    else if not insideComment and indented.test(line)
      out.push line
    else
      insideComment = yes
      out.push "# #{line}"
  out.join '\n'

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
    last_line_exclusive: last.last_line_exclusive
    last_column_exclusive: last.last_column_exclusive
    range: [
      first.range[0]
      last.range[1]
    ]

# Build a list of all comments attached to tokens.
exports.extractAllCommentTokens = (tokens) ->
  allCommentsObj = {}
  for token in tokens when token.comments
    for comment in token.comments
      commentKey = comment.locationData.range[0]
      allCommentsObj[commentKey] = comment
  sortedKeys = Object.keys(allCommentsObj).sort (a, b) -> a - b
  for key in sortedKeys
    allCommentsObj[key]

# Get a lookup hash for a token based on its location data.
# Multiple tokens might have the same location hash, but using exclusive
# location data distinguishes e.g. zero-length generated tokens from
# actual source tokens.
buildLocationHash = (loc) ->
  "#{loc.range[0]}-#{loc.range[1]}"

# Build a dictionary of extra token properties organized by tokens’ locations
# used as lookup hashes.
exports.buildTokenDataDictionary = buildTokenDataDictionary = (tokens) ->
  tokenData = {}
  for token in tokens when token.comments
    tokenHash = buildLocationHash token[2]
    # Multiple tokens might have the same location hash, such as the generated
    # `JS` tokens added at the start or end of the token stream to hold
    # comments that start or end a file.
    tokenData[tokenHash] ?= {}
    if token.comments # `comments` is always an array.
      # For “overlapping” tokens, that is tokens with the same location data
      # and therefore matching `tokenHash`es, merge the comments from both/all
      # tokens together into one array, even if there are duplicate comments;
      # they will get sorted out later.
      (tokenData[tokenHash].comments ?= []).push token.comments...
  tokenData

# This returns a function which takes an object as a parameter, and if that
# object is an AST node, updates that object's locationData.
# The object is returned either way.
exports.addDataToNode = (parserState, firstLocationData, firstValue, lastLocationData, lastValue, forceUpdateLocation = yes) ->
  (obj) ->
    # Add location data.
    locationData = buildLocationData(firstValue?.locationData ? firstLocationData, lastValue?.locationData ? lastLocationData)
    if obj?.updateLocationDataIfMissing? and firstLocationData?
      obj.updateLocationDataIfMissing locationData, forceUpdateLocation
    else
      obj.locationData = locationData

    # Add comments, building the dictionary of token data if it hasn’t been
    # built yet.
    parserState.tokenData ?= buildTokenDataDictionary parserState.parser.tokens
    if obj.locationData?
      objHash = buildLocationHash obj.locationData
      if parserState.tokenData[objHash]?.comments?
        attachCommentsToNode parserState.tokenData[objHash].comments, obj
    obj

exports.attachCommentsToNode = attachCommentsToNode = (comments, node) ->
  return if not comments? or comments.length is 0
  node.comments ?= []
  node.comments.push comments...

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
exports.baseFileName = (file, stripExt = no, useWinPathSep = no) ->
  pathSep = if useWinPathSep then /\\|\// else /\//
  parts = file.split(pathSep)
  file = parts[parts.length - 1]
  return file unless stripExt and file.indexOf('.') >= 0
  parts = file.split('.')
  parts.pop()
  parts.pop() if parts[parts.length - 1] is 'coffee' and parts.length > 1
  parts.join('.')

# Determine if a filename represents a CoffeeScript file.
exports.isCoffee = (file) -> /\.((lit)?coffee|coffee\.md)$/.test file

# Determine if a filename represents a Literate CoffeeScript file.
exports.isLiterate = (file) -> /\.(litcoffee|coffee\.md)$/.test file

# Throws a SyntaxError from a given location.
# The error's `toString` will return an error message following the "standard"
# format `<filename>:<line>:<col>: <message>` plus the line with the error and a
# marker showing where the error is.
exports.throwSyntaxError = (message, location) ->
  error = new SyntaxError message
  error.location = location
  error.toString = syntaxErrorToString

  # Instead of showing the compiler's stacktrace, show our custom error message
  # (this is useful when the error bubbles up in Node.js applications that
  # compile CoffeeScript for example).
  error.stack = error.toString()

  throw error

# Update a compiler SyntaxError with source code information if it didn't have
# it already.
exports.updateSyntaxError = (error, code, filename) ->
  # Avoid screwing up the `stack` property of other errors (i.e. possible bugs).
  if error.toString is syntaxErrorToString
    error.code or= code
    error.filename or= filename
    error.stack = error.toString()
  error

syntaxErrorToString = ->
  return Error::toString.call @ unless @code and @location

  {first_line, first_column, last_line, last_column} = @location
  last_line ?= first_line
  last_column ?= first_column

  filename = @filename or '[stdin]'
  codeLine = @code.split('\n')[first_line]
  start    = first_column
  # Show only the first line on multi-line errors.
  end      = if first_line is last_line then last_column + 1 else codeLine.length
  marker   = codeLine[...start].replace(/[^\s]/g, ' ') + repeat('^', end - start)

  # Check to see if we're running on a color-enabled TTY.
  if process?
    colorsEnabled = process.stdout?.isTTY and not process.env?.NODE_DISABLE_COLORS

  if @colorful ? colorsEnabled
    colorize = (str) -> "\x1B[1;31m#{str}\x1B[0m"
    codeLine = codeLine[...start] + colorize(codeLine[start...end]) + codeLine[end..]
    marker   = colorize marker

  """
    #{filename}:#{first_line + 1}:#{first_column + 1}: error: #{@message}
    #{codeLine}
    #{marker}
  """

exports.nameWhitespaceCharacter = (string) ->
  switch string
    when ' ' then 'space'
    when '\n' then 'newline'
    when '\r' then 'carriage return'
    when '\t' then 'tab'
    else string

exports.parseNumber = (string) ->
  return NaN unless string?

  base = switch string.charAt 1
    when 'b' then 2
    when 'o' then 8
    when 'x' then 16
    else null

  if base?
    parseInt string[2..].replace(/_/g, ''), base
  else
    parseFloat string.replace(/_/g, '')

exports.isFunction = (obj) -> Object::toString.call(obj) is '[object Function]'
exports.isNumber = isNumber = (obj) -> Object::toString.call(obj) is '[object Number]'
exports.isString = isString = (obj) -> Object::toString.call(obj) is '[object String]'
exports.isBoolean = isBoolean = (obj) -> obj is yes or obj is no or Object::toString.call(obj) is '[object Boolean]'
exports.isPlainObject = (obj) -> typeof obj is 'object' and !!obj and not Array.isArray(obj) and not isNumber(obj) and not isString(obj) and not isBoolean(obj)

unicodeCodePointToUnicodeEscapes = (codePoint) ->
  toUnicodeEscape = (val) ->
    str = val.toString 16
    "\\u#{repeat '0', 4 - str.length}#{str}"
  return toUnicodeEscape(codePoint) if codePoint < 0x10000
  # surrogate pair
  high = Math.floor((codePoint - 0x10000) / 0x400) + 0xD800
  low = (codePoint - 0x10000) % 0x400 + 0xDC00
  "#{toUnicodeEscape(high)}#{toUnicodeEscape(low)}"

# Replace `\u{...}` with `\uxxxx[\uxxxx]` in regexes without `u` flag
exports.replaceUnicodeCodePointEscapes = (str, {flags, error, delimiter = ''} = {}) ->
  shouldReplace = flags? and 'u' not in flags
  str.replace UNICODE_CODE_POINT_ESCAPE, (match, escapedBackslash, codePointHex, offset) ->
    return escapedBackslash if escapedBackslash

    codePointDecimal = parseInt codePointHex, 16
    if codePointDecimal > 0x10ffff
      error "unicode code point escapes greater than \\u{10ffff} are not allowed",
        offset: offset + delimiter.length
        length: codePointHex.length + 4
    return match unless shouldReplace

    unicodeCodePointToUnicodeEscapes codePointDecimal

UNICODE_CODE_POINT_ESCAPE = ///
  ( \\\\ )        # Make sure the escape isn’t escaped.
  |
  \\u\{ ( [\da-fA-F]+ ) \}
///g
