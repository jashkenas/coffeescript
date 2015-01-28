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

  name = path.basename __filename, '.coffee'
  compiledPath = path.join deepDir, "#{name}.js"

  process.on 'exit', ->
    exists = fs.existsSync compiledPath

    try
      fs.unlinkSync compiledPath
      fs.rmdirSync 'test/mkdirp/deep/dir'
      fs.rmdirSync 'test/mkdirp/deep'
      fs.rmdirSync 'test/mkdirp'

    ok exists
