fs = require 'fs'

option '-o', '--output [DIR]', 'directory for compiled code'
option '-t', '--timeout [milliseconds]', 'Timeout used by async callbacks'

task 'build:parser', 'rebuild the Jison parser', (options) ->
  require 'jison'
  code = require('./lib/grammar').parser.generate()
  dir  = options.output or 'lib'
  fs.writeFile "#{dir}/parser.js", code

# Add an optional `done` parameter to declare an async task.
task 'longTask', (options, done) ->
  doSomething()
  done()

# Dependencies with an optional callback.
task 'all', ->
  invoke 'longTask', 'build:parser', ->
    console.log "Callback is optional"
    
