# This file defines helpers of compilation and register of callback function of require

fs           = require 'fs'
path         = require 'path'
helpers      = require './helpers'
CoffeeScript = require './coffee-script'

exports.fileExtensions = ['.coffee', '.litcoffee', '.coffee.md']

# Load and run a CoffeeScript file for Node, stripping any `BOM`s.
loadFile = (module, filename) ->
  answer = exports.compileFile filename, false
  module._compile answer, filename

# Register callback functions of require
exports.registerRequire = (require) ->
  # If the installed version of Node supports `require.extensions`, register
  # CoffeeScript as an extension.
  if require.extensions
    for ext in exports.fileExtensions
      require.extensions[ext] = loadFile

    # Patch Node's module loader to be able to handle mult-dot extensions.
    # This is a horrible thing that should not be required. Perhaps, one day,
    # when a truly benevolent dictator comes to rule over the Republik of Node,
    # it won't be.
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

exports.compileFile = (filename, sourceMap) ->
  raw = fs.readFileSync filename, 'utf8'
  stripped = if raw.charCodeAt(0) is 0xFEFF then raw.substring 1 else raw

  try
    answer = CoffeeScript.compile(stripped, {filename, sourceMap, literate: helpers.isLiterate filename})
  catch err
    # As the filename and code of a dynamically loaded file will be different
    # from the original file compiled with CoffeeScript.run, add that
    # information to error so it can be pretty-printed later.
    err.filename = filename
    err.code = stripped
    throw err

  answer
