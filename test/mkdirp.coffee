command = require '../lib/coffee-script/command'
path = require 'path'
fs = require 'fs'

test "mkdirp", ->
  deepDir = 'test/mkdirp/deep/dir'
  process.argv = [
    'node', 'coffee'
    '-o', deepDir
    '-c', __filename
  ]
  command.run()

  compiledPath = path.join(
    deepDir
    path.basename(__filename, '.coffee') + '.js'
  )

  # Coffee's test suit doesn't support async task.
  # Here some hack.
  setTimeout ->
    ok fs.existsSync(compiledPath)
  , 1000

  process.on 'exit', ->
    fs.unlinkSync compiledPath
    fs.rmdirSync 'test/mkdirp/deep/dir'
    fs.rmdirSync 'test/mkdirp/deep'
    fs.rmdirSync 'test/mkdirp'

