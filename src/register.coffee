CoffeeScript  = require './'
child_process = require 'child_process'
helpers       = require './helpers'
path          = require 'path'

{ getSourceMap, registerCompiled } = require "./sourcemap"

# Check if Node's built-in source map stack trace transformations are enabled.
nodeSourceMapsSupportEnabled = process?.execArgv.includes('--enable-source-maps')

unless Error.prepareStackTrace or nodeSourceMapsSupportEnabled
  cacheSourceMaps = true

  # Based on http://v8.googlecode.com/svn/branches/bleeding_edge/src/messages.js
  # Modified to handle sourceMap
  formatSourcePosition = (frame, getSourceMapping) ->
    filename = undefined
    fileLocation = ''

    if frame.isNative()
      fileLocation = "native"
    else
      if frame.isEval()
        filename = frame.getScriptNameOrSourceURL()
        fileLocation = "#{frame.getEvalOrigin()}, " unless filename
      else
        filename = frame.getFileName()

      filename or= "<anonymous>"

      line = frame.getLineNumber()
      column = frame.getColumnNumber()

      # Check for a sourceMap position
      source = getSourceMapping filename, line, column
      fileLocation =
        if source
          "#{filename}:#{source[0]}:#{source[1]}"
        else
          "#{filename}:#{line}:#{column}"

    functionName = frame.getFunctionName()
    isConstructor = frame.isConstructor()
    isMethodCall = not (frame.isToplevel() or isConstructor)

    if isMethodCall
      methodName = frame.getMethodName()
      typeName = frame.getTypeName()

      if functionName
        tp = as = ''
        if typeName and functionName.indexOf typeName
          tp = "#{typeName}."
        if methodName and functionName.indexOf(".#{methodName}") isnt functionName.length - methodName.length - 1
          as = " [as #{methodName}]"

        "#{tp}#{functionName}#{as} (#{fileLocation})"
      else
        "#{typeName}.#{methodName or '<anonymous>'} (#{fileLocation})"
    else if isConstructor
      "new #{functionName or '<anonymous>'} (#{fileLocation})"
    else if functionName
      "#{functionName} (#{fileLocation})"
    else
      fileLocation

  # Based on [michaelficarra/CoffeeScriptRedux](http://goo.gl/ZTx1p)
  # NodeJS / V8 have no support for transforming positions in stack traces using
  # sourceMap, so we must monkey-patch Error to display CoffeeScript source
  # positions.
  Error.prepareStackTrace = (err, stack) ->
    getSourceMapping = (filename, line, column) ->
      sourceMap = getSourceMap filename, line, column

      answer = sourceMap.sourceLocation [line - 1, column - 1] if sourceMap?
      if answer? then [answer[0] + 1, answer[1] + 1] else null

    frames = for frame in stack
      break if frame.getFunction() is exports.run
      "    at #{formatSourcePosition frame, getSourceMapping}"

    "#{err.toString()}\n#{frames.join '\n'}\n"

# Load and run a CoffeeScript file for Node, stripping any `BOM`s.
loadFile = (module, filename) ->
  options = module.options or getRootModule(module).options

  # We may need to cache our own sourcemaps to transform stack traces.
  if cacheSourceMaps
    options.sourceMap = true
    {js, sourceMap} = CoffeeScript._compileFile filename, options
    # TODO may be redundant
    registerCompiled filename, null, sourceMap
  else
    options.inlineMap = true if nodeSourceMapsSupportEnabled
    js = CoffeeScript._compileFile filename, options

  module._compile js, filename

# If the installed version of Node supports `require.extensions`, register
# CoffeeScript as an extension.
if require.extensions
  for ext in CoffeeScript.FILE_EXTENSIONS
    require.extensions[ext] = loadFile

  # Patch Node's module loader to be able to handle multi-dot extensions.
  # This is a horrible thing that should not be required.
  Module = require 'module'

  findExtension = (filename) ->
    extensions = path.basename(filename).split '.'
    # Remove the initial dot from dotfiles.
    extensions.shift() if extensions[0] is ''
    # Start with the longest possible extension and work our way shortwards.
    while extensions.shift()
      curExtension = '.' + extensions.join '.'
      return curExtension if Module._extensions[curExtension]
    '.js'

  Module::load = (filename) ->
    @filename = filename
    @paths = Module._nodeModulePaths path.dirname filename
    extension = findExtension filename
    Module._extensions[extension](this, filename)
    @loaded = true

# If we're on Node, patch `child_process.fork` so that Coffee scripts are able
# to fork both CoffeeScript files, and JavaScript files, directly.
if child_process
  {fork} = child_process
  binary = require.resolve '../../bin/coffee'
  child_process.fork = (path, args, options) ->
    if helpers.isCoffee path
      unless Array.isArray args
        options = args or {}
        args = []
      args = [path].concat args
      path = binary
    fork path, args, options

# Utility function to find the `options` object attached to the topmost module.
getRootModule = (module) ->
  if module.parent then getRootModule module.parent else module
