#### LineMapping

# Hold data about mappings for one line of generated source code.

class LineMapping
  constructor: (@generatedLine) ->
    # columnMap keeps track of which columns we've already mapped.
    @columnMap = {}

    # columnMappings is an array of all column mappings, sorted by generated-column.
    @columnMappings = []

  addMapping: (generatedColumn, [sourceLine, sourceColumn], options={}) ->
    if @columnMap[generatedColumn] and options.noReplace
      # We already have a mapping for this column.
      return

    @columnMap[generatedColumn] = {
      generatedLine: @generatedLine
      generatedColumn
      sourceLine
      sourceColumn
    }

    @columnMappings.push @columnMap[generatedColumn]
    @columnMappings.sort (a,b) -> a.generatedColumn - b.generatedColumn

  getSourcePosition: (generatedColumn) ->
    answer = null
    lastColumnMapping = null
    for columnMapping in @columnMappings
      if columnMapping.generatedColumn > generatedColumn
        break
      else
        lastColumnMapping = columnMapping
    if lastColumnMapping
      answer = [lastColumnMapping.sourceLine, lastColumnMapping.sourceColumn]

#### SourceMap

# Maps locations in a generated source file back to locations in the original source file.
#
# This is intentionally agnostic towards how a source map might be represented on disk.  A
# SourceMap can be converted to a "v3" style sourcemap with `#generateV3SourceMap()`, for example
# but the SourceMap class itself knows nothing about v3 source maps.

class exports.SourceMap
  constructor: () ->
    # `generatedLines` is an array of LineMappings, one per generated line.
    @generatedLines = []

  # Adds a mapping to this SourceMap.
  #
  # `sourceLocation` and `generatedLocation` are both [line, column] arrays.
  #
  # If `options.noReplace` is true, then if there is already a mapping for
  # the specified `generatedLine` and `generatedColumn`, this will have no effect.
  addMapping: (sourceLocation, generatedLocation, options={}) ->
    [generatedLine, generatedColumn] = generatedLocation

    lineMapping = @generatedLines[generatedLine]
    if not lineMapping
      lineMapping = @generatedLines[generatedLine] = new LineMapping(generatedLine)

    lineMapping.addMapping generatedColumn, sourceLocation, options

  # Returns [sourceLine, sourceColumn], or null if no mapping could be found.
  getSourcePosition: ([generatedLine, generatedColumn]) ->
    answer = null
    lineMapping = @generatedLines[generatedLine]
    if not lineMapping
      # TODO: Search backwards for the line?
    else
      answer = lineMapping.getSourcePosition generatedColumn

    answer


  # `fn` will be called once for every recorded mapping, in the order in
  # which they occur in the generated source.  `fn` will be passed an object
  # with four properties: sourceLine, sourceColumn, generatedLine, and
  # generatedColumn.
  forEachMapping: (fn) ->
    for lineMapping, generatedLineNumber in @generatedLines
      if lineMapping
        for columnMapping in lineMapping.columnMappings
          fn(columnMapping)


#### generateV3SourceMap

# Builds a V3 source map from a SourceMap object.
# Returns the generated JSON as a string.
#
# `options.sourceRoot` may be used to specify the sourceRoot written to the source map.  Also,
# `options.sourceFiles` and `options.generatedFile` may be passed to set "sources" and "file",
# respectively.  Note that `sourceFiles` must be an array.

exports.generateV3SourceMap = (sourceMap, options={}) ->
  sourceRoot = options.sourceRoot or ""
  sourceFiles = options.sourceFiles or [""]
  generatedFile = options.generatedFile or ""

  writingGeneratedLine = 0
  lastGeneratedColumnWritten = 0
  lastSourceLineWritten = 0
  lastSourceColumnWritten = 0
  needComma = no

  mappings = ""

  sourceMap.forEachMapping (mapping) ->
    while writingGeneratedLine < mapping.generatedLine
      lastGeneratedColumnWritten = 0
      needComma = no
      mappings += ";"
      writingGeneratedLine++

    # Write a comma if we've already written a segment on this line.
    if needComma
      mappings += ","
      needComma = no

    # Write the next segment.
    # Segments can be 1, 4, or 5 values.  If just one, then it is a generated column which
    # doesn't match anything in the source code.
    #
    # Fields are all zero-based, and relative to the previous occurence unless otherwise noted:
    #  * starting-column in generated source, relative to previous occurence for the current line.
    #  * index into the "sources" list
    #  * starting line in the original source
    #  * starting column in the original source
    #  * index into the "names" list associated with this segment.

    # Add the generated start-column
    mappings += exports.vlqEncodeValue(mapping.generatedColumn - lastGeneratedColumnWritten)
    lastGeneratedColumnWritten = mapping.generatedColumn

    # Add the index into the sources list
    mappings += exports.vlqEncodeValue(0)

    # Add the source start-line
    mappings += exports.vlqEncodeValue(mapping.sourceLine - lastSourceLineWritten)
    lastSourceLineWritten = mapping.sourceLine

    # Add the source start-column
    mappings += exports.vlqEncodeValue(mapping.sourceColumn - lastSourceColumnWritten)
    lastSourceColumnWritten = mapping.sourceColumn

    # TODO: Do we care about symbol names for CoffeeScript? Probably not.

    needComma = yes

  answer = {
    version: 3
    file: generatedFile
    sourceRoot
    sources: sourceFiles
    names: []
    mappings
  }

  return JSON.stringify answer, null, 2

# Load a SourceMap from a JSON string.  Returns the SourceMap object.
exports.loadV3SourceMap = (sourceMap) ->
  todo()

#### Base64 encoding helpers

BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
MAX_BASE64_VALUE = BASE64_CHARS.length - 1

encodeBase64Char = (value) ->
  if value > MAX_BASE64_VALUE
    throw new Error "Cannot encode value #{value} > #{MAX_BASE64_VALUE}"
  else if value < 0
    throw new Error "Cannot encode value #{value} < 0"
  BASE64_CHARS[value]

decodeBase64Char = (char) ->
  value = BASE64_CHARS.indexOf char
  if value == -1
    throw new Error "Invalid Base 64 character: #{char}"
  value

#### Base 64 VLQ encoding/decoding helpers

# Note that SourceMap VLQ encoding is "backwards".  MIDI style VLQ encoding puts the
# most-significant-bit (MSB) from the original value into the MSB of the VLQ encoded value
# (see http://en.wikipedia.org/wiki/File:Uintvar_coding.svg).  SourceMap VLQ does things
# the other way around, with the least significat four bits of the original value encoded
# into the first byte of the VLQ encoded value.

VLQ_SHIFT      = 5
VLQ_CONTINUATION_BIT = 1 << VLQ_SHIFT # 0010 0000
VLQ_VALUE_MASK       = VLQ_CONTINUATION_BIT - 1 # 0001 1111

# Encode a value as Base 64 VLQ.
exports.vlqEncodeValue = (value) ->
  # Least significant bit represents the sign.
  signBit = if value < 0 then 1 else 0

  # Next bits are the actual value
  valueToEncode = (Math.abs(value) << 1) + signBit

  answer = ""
  # Make sure we encode at least one character, even if valueToEncode is 0.
  while valueToEncode || !answer
    nextVlqChunk = valueToEncode & VLQ_VALUE_MASK
    valueToEncode = valueToEncode >> VLQ_SHIFT

    if valueToEncode
      nextVlqChunk |= VLQ_CONTINUATION_BIT

    answer += encodeBase64Char(nextVlqChunk)

  return answer

# Decode a Base 64 VLQ value.
#
# Returns `[value, consumed]` where `value` is the decoded value, and `consumed` is the number
# of characters consumed from `str`.
exports.vlqDecodeValue = (str, offset=0) ->
  position = offset
  done = false

  value = 0
  continuationShift = 0

  while !done
    nextVlqChunk = decodeBase64Char(str[position])
    position += 1

    nextChunkValue = nextVlqChunk & VLQ_VALUE_MASK
    value += (nextChunkValue << continuationShift)

    if !(nextVlqChunk & VLQ_CONTINUATION_BIT)
      # We'll be done after this character.
      done = true

    # Bits are encoded least-significant first (opposite of MIDI VLQ).  Increase the
    # continuationShift, so the next byte will end up where it should in the value.
    continuationShift += VLQ_SHIFT

  consumed = position - offset

  # Least significant bit represents the sign.
  signBit = value & 1
  value = value >> 1

  if signBit then value = -value

  return [value, consumed]