# Hold data about mappings for one line of generated source code.
class LineMapping
    constructor: (@generatedLine) ->
        @columnMap = {}
        @columnMappings = []

    addMapping: (generatedColumn, sourceLine, sourceColumn) ->
        if @columnMap[generatedColumn]
            # We already have a mapping for this column.  Bail.
            return

        @columnMap[generatedColumn] = {
            generatedLine: @generatedLine
            generatedColumn
            sourceLine
            sourceColumn
        }

        @columnMappings.push @columnMap[generatedColumn]

class exports.SourceMap
    constructor: () ->
        # Array of LineMappings, one per generated line.
        @generatedLines = []

    # Adds a mapping to this SourceMap.
    # If there is already a mapping for the specified `generatedLine` and
    # `generatedColumn`, then this will have no effect.
    addMapping: (generatedLine, generatedColumn, sourceLine, sourceColumn) ->
        lineArray = @generatedLines[generatedLine]
        if not lineArray
            lineArray = @generatedLines[generatedLine] = LineMapping(generatedLine)

        lineArray.addMapping generatedColumn, sourceLine, sourceColumn

    # `fn` will be called once for every recorded mapping, in the order in
    # which they occur in the generated source.  `fn` will be passed an object
    # with four properties: generatedLine, generatedColumn, sourceLine, and
    # sourceColumn.
    forEachMapping: (fn) ->
        for lineMapping, generatedLineNumber in @generatedLines
            if lineMapping
                for columnMapping in lineMapping.columnMappings
                    fn(columnMapping)


#### Build a V3 source map from a SourceMap object.
# Returns the generated JSON as a string.
exports.generateV3SourceMap = (sourceMap) ->
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

        if needComma
            mappings += ","
            needComma = no

        # Add the generated start-column
        exports.vlqEncodeValue(mapping.generatedColumn - lastGeneratedColumnWritten)
        lastGeneratedColumnWritten = mapping.generatedColumn

        # Add the index into the sources list
        exports.vlqEncodeValue(0)

        # Add the source start-line
        exports.vlqEncodeValue(mapping.sourceLine - lastSourceLineWritten)
        lastSourceLineWritten = mapping.sourceLine

        # Add the source start-column
        exports.vlqEncodeValue(mapping.sourceColumn - lastSourceColumnWritten)
        lastSourceColumnWritten = mapping.sourceColumn

        # TODO: Do we care about symbol names for CoffeeScript?

        needComma = yes




BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
MAX_BASE64_VALUE = BASE64_CHARS.length - 1

VLQ_SHIFT            = 5
VLQ_MASK             = 0x1F # 0001 1111
VLQ_CONTINUATION_BIT = 0x20 # 0010 0000

encodeBase64Char = (value) ->
    if value > MAX_BASE64_VALUE
        throw Error "Cannot encode value #{value} > #{MAX_BASE64_VALUE}"
    else if value < 0
        throw Error "Cannot encode value #{value} < 0"
    BASE64_CHARS[value]

exports.vlqEncodeValue = (value) ->
    # Least significant bit represents the sign.
    value = if value < 0 then 1 else 0

    # Next bits are the actual value
    value += Math.abs(value) << 1

    answer = ""
    while value
        nextVlqChunk = value & VLQ_MASK
        value >> VLQ_SHIFT

        if value
            nextVlqChunk |= VLQ_CONTINUATION_BIT

        answer += encodeBase64Char(nextVlqChunk)
