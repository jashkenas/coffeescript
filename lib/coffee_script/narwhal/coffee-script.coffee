# The Narwhal-compatibility wrapper for CoffeeScript.

# Require external dependencies.
OS:       require 'os'
File:     require 'file'
Readline: require 'readline'

# The path to the CoffeeScript Compiler.
coffeePath: File.path(module.path).dirname().dirname().dirname().dirname().join('bin', 'coffee')

# Our general-purpose error handler.
checkForErrors: (coffeeProcess) ->
  return true if coffeeProcess.wait() is 0
  system.stderr.print coffeeProcess.stderr.read()
  throw new Error "CoffeeScript compile error"

# Run a simple REPL, round-tripping to the CoffeeScript compiler for every
# command.
exports.run: (args) ->
  if args.length
    for path, i in args
      exports.evalCS File.read path
      delete args[i]
    return true

  while true
    try
      system.stdout.write('coffee> ').flush()
      result: exports.evalCS Readline.readline(), ['--globals']
      print result if result isnt undefined
    catch e
      print e

# Compile a given CoffeeScript file into JavaScript.
exports.compileFile: (path) ->
  coffee: OS.popen [coffeePath, "--print", "--no-wrap", path]
  checkForErrors coffee
  coffee.stdout.read()

# Compile a string of CoffeeScript into JavaScript.
exports.compile: (source, flags) ->
  coffee: OS.popen [coffeePath, "--eval", "--no-wrap"].concat flags or []
  coffee.stdin.write(source).flush().close()
  checkForErrors coffee
  coffee.stdout.read()

# Evaluating a string of CoffeeScript first compiles it externally.
exports.evalCS: (source, flags) ->
  eval exports.compile source, flags

# Make a factory for the CoffeeScript environment.
exports.makeNarwhalFactory: (path) ->
  code: exports.compileFile path
  factoryText: "function(require,exports,module,system,print){" + code + "/**/\n}"
  if system.engine is "rhino"
    Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(global, factoryText, path, 0, null)
  else
    # eval requires parentheses, but parentheses break compileFunction.
    eval "(" + factoryText + ")"

# The Narwhal loader for '.coffee' files.
factories: {}
loader:    {}

# Reload the coffee-script environment from source.
loader.reload: (topId, path) ->
  factories[topId]: ->
    exports.makeNarwhalFactory path

# Ensure that the coffee-script environment is loaded.
loader.load: (topId, path) ->
  factories[topId] ||= this.reload topId, path

require.loader.loaders.unshift [".coffee", loader]
