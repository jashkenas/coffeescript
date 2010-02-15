# Set up for both the browser and the server.
if process?
  process.mixin require './nodes'
  path:         require 'path'
  lexer:   new (require('./lexer').Lexer)()
  parser:       require('./parser').parser
else
  this.exports: this
  lexer: new Lexer()
  parser: exports.parser

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

# Improved error messages.
# parser.parseError: (message, hash) ->
#   throw new Error 'Unexpected ' + parser.terminals_[hash.token] + ' on line ' + hash.line

exports.VERSION: '0.5.0'

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
  strings.join(' ')


#---------- Below this line is obsolete, for the Ruby compiler. ----------------

# The path to the CoffeeScript executable.
compiler: ->
  path.normalize(path.dirname(__filename) + '/../../bin/coffee')

# Compile a string over stdin, with global variables, for the REPL.
exports.ruby_compile: (code, callback) ->
  js: ''
  coffee: process.createChildProcess compiler(), ['--eval', '--no-wrap', '--globals']

  coffee.addListener 'output', (results) ->
    js += results if results?

  coffee.addListener 'exit', ->
    callback(js)

  coffee.write(code)
  coffee.close()


# Compile a list of CoffeeScript files on disk.
exports.ruby_compile_files: (paths, callback) ->
  js: ''
  coffee: process.createChildProcess compiler(), ['--print'].concat(paths)

  coffee.addListener 'output', (results) ->
    js += results if results?

  # NB: we have to add a mutex to make sure it doesn't get called twice.
  exit_ran: false
  coffee.addListener 'exit', ->
    return if exit_ran
    exit_ran: true
    callback(js)

  coffee.addListener 'error', (message) ->
    return unless message
    puts message
    throw new Error "CoffeeScript compile error"
