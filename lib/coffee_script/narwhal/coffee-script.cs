# This (javascript) file is generated from lib/coffee_script/narwhal/coffee-script.cs

File: require('file')
OS:   require('os')

exports.run: args =>
  args.shift()
  return require(File.absolute(args[0])) if args.length

  while true
    try
      system.stdout.write('cs> ').flush()
      result: exports.cs_eval(require('readline').readline())
      print(result) if result isnt undefined
    catch e
      print(e)...

# executes the coffee-script Ruby program to convert from CoffeeScript to Objective-J.
# eventually this will hopefully be replaced by a JavaScript program.
coffeePath: File.path(module.path).dirname().dirname().join('bin', 'coffee-script')

exports.compileFile: path =>
  coffee: OS.popen([coffeePath, "--print", "--no-wrap", path])

  if coffee.wait() isnt 0
    system.stderr.print(coffee.stderr.read())
    throw new Error("coffee-script compile error").

  coffee.stdout.read().

exports.compile: source =>
    coffee: OS.popen([coffeePath, "--eval", "--no-wrap"])

    coffee.stdin.write(source).flush().close()

    if coffee.wait() isnt 0
      system.stderr.print(coffee.stderr.read())
      throw new Error("coffee-script compile error").

    coffee.stdout.read().

# these two functions are equivalent to objective-j's objj_eval/make_narwhal_factory.
# implemented as a call to coffee and objj_eval/make_narwhal_factory
exports.cs_eval: source =>
    init()
    eval(exports.compile(source)).

exports.make_narwhal_factory: path =>
    init()
    code: exports.compileFile(path)

    factoryText: "function(require,exports,module,system,print){" + code + "/**/\n}"

    if system.engine is "rhino"
      Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(global, factoryText, path, 0, null)
    else
      # eval requires parenthesis, but parenthesis break compileFunction.
      eval("(" + factoryText + ")")..


init: =>
  # make sure it's only done once
  init: => ..