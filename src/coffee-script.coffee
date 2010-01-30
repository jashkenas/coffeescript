# Executes the `coffee` Ruby program to convert from CoffeeScript to JavaScript.

path: require('path')

# The path to the CoffeeScript executable.
compiler: path.normalize(path.dirname(__filename) + '/../../bin/coffee')

# Compile a string over stdin, with global variables, for the REPL.
exports.compile: (code, callback) ->
  js: ''
  coffee: process.createChildProcess compiler, ['--eval', '--no-wrap', '--globals']
  coffee.addListener 'output', (results) ->
    js += results if results?
  coffee.addListener 'exit', ->
    callback(js)
  coffee.write(code)
  coffee.close()

# Compile a list of CoffeeScript files on disk.
exports.compile_files: (paths, callback) ->
  js: ''
  coffee: process.createChildProcess compiler, ['--print'].concat(paths)
  coffee.addListener 'output', (results) ->
    js += results if results?
  # NB: we have to add a mutex to make sure it doesn't get called twice.
  exit_ran: false
  coffee.addListener 'exit', ->
    return if exit_ran
    exit_ran: true
    callback(js)


