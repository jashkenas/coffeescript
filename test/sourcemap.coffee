return if global.testingBrowser

SourceMap = require '../src/sourcemap'

vlqEncodedValues = [
    [1, 'C'],
    [-1, 'D'],
    [2, 'E'],
    [-2, 'F'],
    [0, 'A'],
    [16, 'gB'],
    [948, 'o7B']
]

test "encodeVlq tests", ->
  for pair in vlqEncodedValues
    eq ((new SourceMap).encodeVlq pair[0]), pair[1]

test "SourceMap tests", ->
  map = new SourceMap
  map.add [0, 0], [0, 0]
  map.add [1, 5], [2, 4]
  map.add [1, 6], [2, 7]
  map.add [1, 9], [2, 8]
  map.add [3, 0], [3, 4]

  testWithFilenames = map.generate {
    sourceRoot: ''
    sourceFiles: ['source.coffee']
    generatedFile: 'source.js'
  }

  deepEqual testWithFilenames, {
    version: 3
    file: 'source.js'
    sourceRoot: ''
    sources: ['source.coffee']
    names: []
    mappings: 'AAAA;;IACK,GAAC,CAAG;IAET'
  }

  deepEqual map.generate(), {
    version: 3
    file: ''
    sourceRoot: ''
    sources: ['<anonymous>']
    names: []
    mappings: 'AAAA;;IACK,GAAC,CAAG;IAET'
  }

  # Look up a generated column - should get back the original source position.
  arrayEq map.sourceLocation([2,8]), [1,9]

  # Look up a point further along on the same line - should get back the same source position.
  arrayEq map.sourceLocation([2,10]), [1,9]

test "#3075: v3 source map fields", ->
  { js, v3SourceMap, sourceMap } = CoffeeScript.compile 'console.log Date.now()',
    filename: 'tempus_fugit.coffee'
    sourceMap: yes
    sourceRoot: './www_root/coffee/'

  v3SourceMap = JSON.parse v3SourceMap
  arrayEq v3SourceMap.sources, ['tempus_fugit.coffee']
  eq v3SourceMap.sourceRoot, './www_root/coffee/'
