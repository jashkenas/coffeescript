# CoffeeScript can be used both on the server, as a command-line compiler based
# on Node.js/V8, or to run CoffeeScripts directly in the browser. This module
# contains the main entry functions for tokenzing, parsing, and compiling source
# CoffeeScript into JavaScript.
#
# If included on a webpage, it will automatically sniff out, compile, and
# execute all scripts present in `text/coffeescript` tags.

# Set up dependencies correctly for both the server and the browser.
if process?
  path    = require 'path'
  Lexer   = require('./lexer').Lexer
  parser  = require('./parser').parser
  helpers = require('./helpers').helpers
  helpers.extend global, require './nodes'
  if require.registerExtension
    require.registerExtension '.coffee', (content) -> compile content
else
  this.exports = this.CoffeeScript = {}
  Lexer        = this.Lexer
  parser       = this.parser
  helpers      = this.helpers

# The current CoffeeScript version number.
exports.VERSION = '0.9.3'

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
exports.tokens = (code) ->
  lexer.tokenize code

# Tokenize and parse a string of CoffeeScript code, and return the AST. You can
# then compile it by calling `.compile()` on the root, or traverse it by using
# `.traverse()` with a callback.
exports.nodes = (code) ->
  parser.parse lexer.tokenize code

# Compile and execute a string of CoffeeScript (on the server), correctly
# setting `__filename`, `__dirname`, and relative `require()`.
exports.run = (code, options) ->
  module.filename = __filename = options.fileName
  __dirname = path.dirname __filename
  eval exports.compile code, options

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
