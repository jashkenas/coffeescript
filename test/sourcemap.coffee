return if global.testingBrowser

{spawn, fork} = require('child_process')
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

test "node --enable-source-map built in stack trace mapping", ->
  new Promise (resolve, reject) ->
    proc = fork './test/importing/error.coffee', [
      '--enable-source-maps'
    ], stdio: 'pipe'

    err = ''
    proc.stderr.setEncoding 'utf8'
    proc.stderr.on 'data', (str) -> err += str
    proc.on 'close', ->
      try
        match = err.match /error\.coffee:(\d+):(\d+)/
        throw new Error err unless match

        [_, line, column] = match
        equal line, 3 # Mapped source line
        equal column, 9 # Mapped source column

        resolve()
      catch exception
        reject exception

if Number(process.versions.node.split('.')[0]) >= 14
  test "NODE_OPTIONS=--enable-source-maps environment variable stack trace mapping", ->
    new Promise (resolve, reject) ->
      proc = fork './test/importing/error.coffee', [],
        env:
          NODE_OPTIONS: '--enable-source-maps'
        stdio: 'pipe'

      err = ''
      proc.stderr.setEncoding 'utf8'
      proc.stderr.on 'data', (str) -> err += str
      proc.on 'close', ->
        try
          match = err.match /error\.coffee:(\d+):(\d+)/
          throw new Error err unless match

          [_, line, column] = match
          equal line, 3 # Mapped source line
          equal column, 9 # Mapped source column

          resolve()
        catch exception
          reject exception

  test "generate correct stack traces with --enable-source-maps from bin/coffee", ->
    new Promise (resolve, reject) ->
      proc = fork 'test/importing/error.coffee',
        ['--enable-source-maps'],
        stdio: 'pipe'

      err = ""
      proc.stderr.setEncoding 'utf8'
      proc.stderr.on 'data', (str) -> err += str
      proc.on 'close', ->
        try
          match = err.match /error\.coffee:(\d+):(\d+)/
          throw new Error err unless match

          [_, line, column] = match
          equal line, 3 # Mapped source line
          equal column, 9 # Mapped source column

          resolve()
        catch exception
          reject exception

test "don't change stack traces if another library has patched `Error.prepareStackTrace`", ->
  new Promise (resolve, reject) ->
    # This uses `spawn` rather than the preferred `fork` because `fork` requires
    # loading code in a separate file. The `--eval` here shows exactly what is
    # executing without indirection.
    proc = spawn 'node', [
      '--eval', """
        const patchedPrepareStackTrace = Error.prepareStackTrace = function() {};
        require('./register.js');
        process.stdout.write(Error.prepareStackTrace === patchedPrepareStackTrace ? 'preserved' : 'overwritten');
      """
    ]

    out = ''
    proc.stdout.setEncoding 'utf8'
    proc.stdout.on 'data', (str) -> out += str

    proc.on 'close', (status) ->
      try
        equal status, 0
        equal out, 'preserved'

        resolve()
      catch exception
        reject exception

test "requiring 'CoffeeScript' doesn't change `Error.prepareStackTrace`", ->
  new Promise (resolve, reject) ->
    # This uses `spawn` rather than the preferred `fork` because `fork` requires
    # loading code in a separate file. The `--eval` here shows exactly what is
    # executing without indirection.
    proc = spawn 'node', [
      '--eval', """
        require('./lib/coffeescript/coffeescript.js');
        process.stdout.write(Error.prepareStackTrace === undefined ? 'unused' : 'defined');
      """
    ]

    out = ''
    proc.stdout.setEncoding 'utf8'
    proc.stdout.on 'data', (str) -> out += str

    proc.on 'close', (status) ->
      try
        equal status, 0
        equal out, 'unused'

        resolve()
      catch exception
        reject exception
