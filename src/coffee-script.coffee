# CoffeeScript can be used both on the server, as a command-line compiler based
# on Node.js/V8, or to run CoffeeScripts directly in the browser. This module
# contains the main entry functions for tokenzing, parsing, and compiling source
# CoffeeScript into JavaScript.
#
# If included on a webpage, it will automatically sniff out, compile, and
# execute all scripts present in `text/coffeescript` tags.

# Set up dependencies correctly for both the server and the browser.
if process?
  process.mixin require 'nodes'
  path:         require 'path'
  lexer:   new (require('lexer').Lexer)()
  parser:       require('parser').parser
else
  lexer: new Lexer()
  parser: exports.parser
  this.exports: this.CoffeeScript: {}

# The current CoffeeScript version number.
exports.VERSION: '0.5.4'

# Compile a string of CoffeeScript code to JavaScript, using the Coffee/Jison
# compiler.
exports.compile: (code, options) ->
  (parser.parse lexer.tokenize code).compile options

# Tokenize a string of CoffeeScript code, and return the array of tokens.
exports.tokens: (code) ->
  lexer.tokenize code

# Tokenize and parse a string of CoffeeScript code, and return the AST. You can
# then compile it by calling `.compile()` on the root, or traverse it by using
# `.traverse()` with a callback.
exports.nodes: (code) ->
  parser.parse lexer.tokenize code

# The real Lexer produces a generic stream of tokens. This object provides a
# thin wrapper around it, compatible with the Jison API. We can then pass it
# directly as a "Jison lexer".
parser.lexer: {
  lex: ->
    token: @tokens[@pos] or [""]
    @pos += 1
    this.yylineno: token[2]
    this.yytext:   token[1]
    token[0]
  setInput: (tokens) ->
    @tokens: tokens
    @pos: 0
  upcomingInput: -> ""
  showPosition: -> @pos
}

# Activate CoffeeScript in the browser by having it compile and evaluate
# all script tags with a content-type of `text/coffeescript`. This happens
# on page load. Unfortunately, the text contents of remote scripts cannot be
# accessed from the browser, so only inline script tags will work.
if document? and document.getElementsByTagName
  process_scripts: ->
    for tag in document.getElementsByTagName('script') when tag.type is 'text/coffeescript'
      eval exports.compile tag.innerHTML
  if window.addEventListener
    window.addEventListener 'load', process_scripts, false
  else if window.attachEvent
    window.attachEvent 'onload', process_scripts
