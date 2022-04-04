return if global.testingBrowser

{spawn} = require('child_process')
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

# Source maps aren't accurate on Node v12 ??
if process.version.split(".")[0] != "v12"
  test "native source maps", ->
    new Promise (resolve, reject) ->
      proc = spawn "node", [
        "--enable-source-maps"
        '--require', './register.js'
        '--require', './test/importing/error.coffee'
      ]

      # proc.stdout.setEncoding('utf8')
      # proc.stdout.on 'data', (s) -> console.log(s)
      err = ""
      proc.stderr.setEncoding('utf8')
      proc.stderr.on 'data', (s) -> err += s
      proc.on        'exit', (status) ->
        try
          equal status, 1

          [_, line] = err.match /error\.coffee:(\d+)/
          equal line, 3 # Mapped source line
          resolve()
        catch e
          reject(e)

test "don't change stack traces if another library has patched `Error.prepareStackTrace`", ->
  new Promise (resolve, reject) ->
    proc = spawn "node", [
      "-r", "./test/integration/prepare_stack_trace.js",
      "-r", "./register.js",
      "-r", "./test/integration/error.coffee",
    ]

    # proc.stdout.setEncoding('utf8')
    # proc.stdout.on 'data', (s) -> console.log(s)
    err = ""
    proc.stderr.setEncoding('utf8')
    proc.stderr.on 'data', (s) -> err += s
    proc.on        'exit', (status) ->
      try
        equal status, 1

        match = err.match /error\.coffee:(\d+)/
        if match
          [_, line] = match
          equal line, 4 # Unmapped source line
          resolve()
        else
          reject new Error err
      catch e
        reject(e)
