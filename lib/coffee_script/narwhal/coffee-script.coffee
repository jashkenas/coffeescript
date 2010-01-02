# This (javascript) file is generated from lib/coffee_script/narwhal/coffee-script.coffee

# Executes the `coffee` Ruby program to convert from CoffeeScript
# to Javascript. Eventually this will hopefully happen entirely within JS.

# Require external dependencies.
OS:       require('os')
File:     require('file')
Readline: require('readline')

# The path to the CoffeeScript Compiler.
coffeePath: File.path(module.path).dirname().dirname().dirname().dirname().dirname().join('bin', 'coffee')

# Our general-purpose error handler.
checkForErrors: coffeeProcess =>
  return true if coffeeProcess.wait() is 0
  system.stderr.print(coffeeProcess.stderr.read())
  throw new Error("CoffeeScript compile error")

# Run a simple REPL, round-tripping to the CoffeeScript compiler for every
# command.
exports.run: args =>
  if args.length
    for path, i in args
      exports.evalCS(File.read(path))
      delete args[i]
    return true

  while true
    try
      system.stdout.write('coffee> ').flush()
      result: exports.evalCS(Readline.readline())
      print(result) if result isnt undefined
    catch e
      print(e)

# Compile a given CoffeeScript file into JavaScript.
exports.compileFile: path =>
  coffee: OS.popen([coffeePath, "--print", "--no-wrap", path])
  checkForErrors(coffee)
  coffee.stdout.read()

# Compile a string of CoffeeScript into JavaScript.
exports.compile: source =>
  coffee: OS.popen([coffeePath, "--eval", "--no-wrap"])
  coffee.stdin.write(source).flush().close()
  checkForErrors(coffee)
  coffee.stdout.read()

# Evaluating a string of CoffeeScript first compiles it externally.
exports.evalCS: source =>
  eval(exports.compile(source))

# Make a factory for the CoffeeScript environment.
exports.makeNarwhalFactory: path =>
  code: exports.compileFile(path)
  factoryText: "function(require,exports,module,system,print){" + code + "/**/\n}"
  if system.engine is "rhino"
    Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(global, factoryText, path, 0, null)
  else
    # eval requires parentheses, but parentheses break compileFunction.
    eval("(" + factoryText + ")")
