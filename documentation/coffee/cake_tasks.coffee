fs = require 'fs'

option '-o', '--output [DIR]', 'directory for compiled code'
option '-t', '--timeout [milleseconds]', 'Timeout used by async callbacks'

task 'build:parser', 'rebuild the Jison parser', (options) ->
    require 'jison'
    code = require('./lib/grammar').parser.generate()
    dir  = options.output or 'lib'
    fs.writeFile "#{dir}/parser.js", code

# Add an optional `done` parameter to declare an async task. Tiemout 
# exception occurs if `done` is not called.
task 'longTask', (options, done) ->
  doSomething()
  done()

# Dependencies with an optional callback.
task 'all', ->
  invoke 'longTask', 'build:parser', ->
    console.log "Callback is optional"
    
