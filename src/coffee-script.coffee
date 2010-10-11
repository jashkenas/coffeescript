# CoffeeScript can be used both on the server, as a command-line compiler based
# on Node.js/V8, or to run CoffeeScripts directly in the browser. This module
# contains the main entry functions for tokenzing, parsing, and compiling source
# CoffeeScript into JavaScript.
#
# If included on a webpage, it will automatically sniff out, compile, and
# execute all scripts present in `text/coffeescript` tags.

path      = require 'path'
{Lexer}   = require './lexer'
{parser}  = require './parser'

# TODO: Remove registerExtension when fully deprecated
if require.extensions
  fs = require 'fs'
  require.extensions['.coffee'] = (module, filename) ->
    content = compile fs.readFileSync filename, 'utf8'
    module._compile content, filename
else if require.registerExtension
  require.registerExtension '.coffee', (content) -> compile content

# The current CoffeeScript version number.
exports.VERSION = '0.9.4'

# Expose helpers for testing.
exports.helpers = require './helpers'

# Compile a string of CoffeeScript code to JavaScript, using the Coffee/Jison
# compiler.
exports.compile = compile = (code, options) ->
  options or= {}
  try
    (parser.parse lexer.tokenize code).compile options
  catch err
    err.message = "In #{options.fileName}, #{err.message}" if options.fileName
    throw err

# Tokenize a string of CoffeeScript code, and return the array of tokens.
exports.tokens = (code, options) ->
  lexer.tokenize code, options

# Tokenize and parse a string of CoffeeScript code, and return the AST. You can
# then compile it by calling `.compile()` on the root, or traverse it by using
# `.traverse()` with a callback.
exports.nodes = (code, options) ->
  parser.parse lexer.tokenize code, options

# Compile and execute a string of CoffeeScript (on the server), correctly
# setting `__filename`, `__dirname`, and relative `require()`.
exports.run = (code, options) ->
  # We want the root module.
  root = module
  while root.parent
    root = root.parent
  # Set the filename
  root.filename = options.fileName
  # Clear the module cache
  root.moduleCache = {} if root.moduleCache
  # Compile
  if path.extname(root.filename) isnt '.coffee' or require.extensions
    root._compile exports.compile(code, options), root.filename
  else
    root._compile code, root.filename

# Compile and evaluate a string of CoffeeScript (in a Node.js-like environment).
# The CoffeeScript REPL uses this to run the input.
exports.eval = (code, options) ->
  __filename = options.fileName
  __dirname  = path.dirname __filename
  eval exports.compile(code, options)

# Instantiate a Lexer for our use here.
lexer = new Lexer

# The real Lexer produces a generic stream of tokens. This object provides a
# thin wrapper around it, compatible with the Jison API. We can then pass it
# directly as a "Jison lexer".
parser.lexer =
  lex: ->
    token = @tokens[@pos] or [""]
    @pos += 1
    this.yylineno = token[2]
    this.yytext   = token[1]
    token[0]
  setInput: (tokens) ->
    @tokens = tokens
    @pos    = 0
  upcomingInput: -> ""

parser.yy = require './nodes'
