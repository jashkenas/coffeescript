return if global.testingBrowser

SourceMap = require '../src/sourcemap'

vlqEncodedValues = [
    [1, "C"],
    [-1, "D"],
    [2, "E"],
    [-2, "F"],
    [0, "A"],
    [16, "gB"],
    [948, "o7B"]
]

test "encodeVlq tests", ->
  for pair in vlqEncodedValues
    eq ((new SourceMap).encodeVlq pair[0]), pair[1]

eqJson = (a, b) ->
  eq (JSON.stringify JSON.parse a), (JSON.stringify JSON.parse b)

test "SourceMap tests", ->
  map = new SourceMap
  map.add [0, 0], [0, 0]
  map.add [1, 5], [2, 4]
  map.add [1, 6], [2, 7]
  map.add [1, 9], [2, 8]
  map.add [3, 0], [3, 4]

  testWithFilenames = map.generate {
        sourceRoot: "",
        sourceFiles: ["source.coffee"],
        generatedFile: "source.js"}
  eqJson testWithFilenames, '{"version":3,"file":"source.js","sourceRoot":"","sources":["source.coffee"],"names":[],"mappings":"AAAA;;IACK,GAAC,CAAG;IAET"}'
  eqJson map.generate(), '{"version":3,"file":"","sourceRoot":"","sources":[""],"names":[],"mappings":"AAAA;;IACK,GAAC,CAAG;IAET"}'

  # Look up a generated column - should get back the original source position.
  arrayEq map.sourceLocation([2,8]), [1,9]

  # Look up a point futher along on the same line - should get back the same source position.
  arrayEq map.sourceLocation([2,10]), [1,9]
