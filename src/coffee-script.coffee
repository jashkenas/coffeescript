# Set up for both the browser and the server.
if process?
  process.mixin require 'nodes'
  path:         require 'path'
  lexer:   new (require('lexer').Lexer)()
  parser:       require('parser').parser
else
  lexer: new Lexer()
  parser: exports.parser
  this.exports: this.CoffeeScript: {}

# Thin wrapper for Jison compatibility around the real lexer.
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

exports.VERSION: '0.5.2'

# Compile CoffeeScript to JavaScript, using the Coffee/Jison compiler.
exports.compile: (code, options) ->
  (parser.parse lexer.tokenize code).compile(options)

# Just the tokens.
exports.tokens: (code) ->
  lexer.tokenize code

# Just the nodes.
exports.nodes: (code) ->
  parser.parse lexer.tokenize code

# Activate CoffeeScript in the browser by having it compile and eval
# all script tags with a content-type of text/coffeescript.
if document? and document.getElementsByTagName
  process_scripts: ->
    for tag in document.getElementsByTagName('script') when tag.type is 'text/coffeescript'
      eval exports.compile tag.innerHTML
  if window.addEventListener
    window.addEventListener 'load', process_scripts, false
  else if window.attachEvent
    window.attachEvent 'onload', process_scripts
