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

exports.VERSION: '0.5.1'

# Compile CoffeeScript to JavaScript, using the Coffee/Jison compiler.
exports.compile: (code, options) ->
  (parser.parse lexer.tokenize code).compile(options)

# Just the tokens.
exports.tokenize: (code) ->
  lexer.tokenize code

# Just the nodes.
exports.tree: (code) ->
  parser.parse lexer.tokenize code

# Pretty-print a token stream.
exports.print_tokens: (tokens) ->
  strings: for token in tokens
    '[' + token[0] + ' ' + token[1].toString().replace(/\n/, '\\n') + ']'
  puts strings.join(' ')
