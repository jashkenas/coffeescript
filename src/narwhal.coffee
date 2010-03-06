# The Narwhal-compatibility wrapper for CoffeeScript.

# Require external dependencies.
os:       require 'os'
file:     require 'file'
coffee:   require './coffee-script'

# Alias print to "puts", for Node.js compatibility:
puts: print

# Compile a string of CoffeeScript into JavaScript.
exports.compile: (source) ->
  coffee.compile source

# Compile a given CoffeeScript file into JavaScript.
exports.compileFile: (path) ->
  coffee.compile file.read path

# Make a factory for the CoffeeScript environment.
exports.makeNarwhalFactory: (path) ->
  code: exports.compileFile path
  factoryText: "function(require,exports,module,system,print){$code/**/\n}"
  if system.engine is "rhino"
    Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(global, factoryText, path, 0, null)
  else
    # eval requires parentheses, but parentheses break compileFunction.
    eval "($factoryText)"

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
