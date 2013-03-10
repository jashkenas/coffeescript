return if global.testingBrowser

sourcemap = require '../src/sourcemap'

vlqEncodedValues = [
    [1, "C"],
    [-1, "D"],
    [2, "E"],
    [-2, "F"],
    [0, "A"],
    [16, "gB"],
    [948, "o7B"]
]

test "vlqEncodeValue tests", ->
  for pair in vlqEncodedValues
    eq (sourcemap.vlqEncodeValue pair[0]), pair[1]

test "vlqDecodeValue tests", ->
  for pair in vlqEncodedValues
    arrayEq (sourcemap.vlqDecodeValue pair[1]), [pair[0], pair[1].length]

test "vlqDecodeValue with offset", ->
  for pair in vlqEncodedValues
    # Try with an offset, and some cruft at the end.
    arrayEq (sourcemap.vlqDecodeValue ("abc" + pair[1] + "efg"), 3), [pair[0], pair[1].length]

eqJson = (a, b) ->
  eq (JSON.stringify JSON.parse a), (JSON.stringify JSON.parse b)

test "SourceMap tests", ->
  map = new sourcemap.SourceMap()
  map.addMapping [0, 0], [0, 0]
  map.addMapping [1, 5], [2, 4]
  map.addMapping [1, 6], [2, 7]
  map.addMapping [1, 9], [2, 8]
  map.addMapping [3, 0], [3, 4]

  testWithFilenames = sourcemap.generateV3SourceMap map, {
        sourceRoot: "",
        sourceFiles: ["source.coffee"],
        generatedFile: "source.js"}
  eqJson testWithFilenames, '{"version":3,"file":"source.js","sourceRoot":"","sources":["source.coffee"],"names":[],"mappings":"AAAA;;IACK,GAAC,CAAG;IAET"}'
  eqJson (sourcemap.generateV3SourceMap map), '{"version":3,"file":"","sourceRoot":"","sources":[""],"names":[],"mappings":"AAAA;;IACK,GAAC,CAAG;IAET"}'

  # Look up a generated column - should get back the original source position.
  arrayEq map.getSourcePosition([2,8]), [1,9]

  # Look up a point futher along on the same line - should get back the same source position.
  arrayEq map.getSourcePosition([2,10]), [1,9]
