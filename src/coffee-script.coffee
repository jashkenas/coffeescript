# CoffeeScript can be used both on the server, as a command-line compiler based
# on Node.js/V8, or to run CoffeeScripts directly in the browser. This module
# contains the main entry functions for tokenizing, parsing, and compiling
# source CoffeeScript into JavaScript.
#
# If included on a webpage, it will automatically sniff out, compile, and
# execute all scripts present in `text/coffeescript` tags.

fs               = require 'fs'
path             = require 'path'
vm               = require 'vm'
{Lexer,RESERVED} = require './lexer'
{parser}         = require './parser'
{printLinenos}   = require './nodes'

# TODO: Remove registerExtension when fully deprecated.
if require.extensions
  require.extensions['.coffee'] = (module, filename) ->
    content = compile fs.readFileSync(filename, 'utf8'), {filename}
    module._compile content, filename
else if require.registerExtension
  require.registerExtension '.coffee', (content) -> compile content

# The current CoffeeScript version number.
exports.VERSION = '1.1.1'

# Words that cannot be used as identifiers in CoffeeScript code
exports.RESERVED = RESERVED

# Expose helpers for testing.
exports.helpers = require './helpers'

# Compile a string of CoffeeScript code to JavaScript, using the Coffee/Jison
# compiler.
exports.compile = compile = (code, options = {}) ->
  try
    (parser.parse lexer.tokenize code).compile options
  catch err
    err.message = "In #{options.filename}, #{err.message}" if options.filename
    throw err

# Tokenize a string of CoffeeScript code, and return the array of tokens.
exports.tokens = (code, options) ->
  lexer.tokenize code, options

# Parse a string of CoffeeScript code or an array of lexed tokens, and
# return the AST. You can then compile it by calling `.compile()` on the root,
# or traverse it by using `.traverse()` with a callback.
exports.nodes = (source, options) ->
  if typeof source is 'string'
    parser.parse lexer.tokenize source, options
  else
    parser.parse source

# Compile and execute a string of CoffeeScript (on the server), correctly
# setting `__filename`, `__dirname`, and relative `require()`.
exports.run = (code, options) ->
  mainModule = require.main

  # Set the filename.
  mainModule.filename = process.argv[1] =
      if options.filename then fs.realpathSync(options.filename) else '.'

  # Clear the module cache.
  mainModule.moduleCache and= {}

  # Assign paths for node_modules loading
  if process.binding('natives').module
    {Module} = require 'module'
    mainModule.paths = Module._nodeModulePaths path.dirname options.filename

  # Compile.
  if path.extname(mainModule.filename) isnt '.coffee' or require.extensions
    js = compile(code, options)
  else
    js = code
  
  # Debug.
  try
    mainModule._compile js, mainModule.filename
  catch err
    err.debug = debug code, err.stack.split('\n'), options, js if options.debug
    # Node.js reports the error is from the .coffee file, when it's actually occuring in the
    # compiled .js file
    # [fixes issue #987] (https://github.com/jashkenas/coffee-script/issues/987)
    err.stack = err.stack.replace /\.coffee\:/g, '.js:'
    # forward on the runtime's error (handled by `command.coffee`)
    throw err
  true

# Debugging
# ---------
# If a .coffee script successfully compiles into JavaScript, but the runtime throws an error,
# the --debug option will map the error in the output JavaScript with the associated
# CoffeeScript line
debug = (code,stack,options,ojs) ->
    # print the error message as reported by the runtime
    msg = "\n  #{stack[0]}\n\n"

    # The script is re-compiled, this time with printed line numbers placed next to
    # each element of js code (as inlined block comments)
    #
    #   f = (i) -> log i
    #
    # after `compile`, becomes:
    #
    #   f = function(i) {
    #     return log(i);
    #   };
    #
    # after `printLinenos()` becomes:
    #
    #   f/*@line: 3*/ = function(i/*@line: 3*/) {
    #     return log/*@line: 3*/(i/*@line: 3*/);
    #   };

    # ojs is the original js output, so we can reference the line without line numbers
    #    f = function(i) { ...

    # `printLinenos` from Nodes.coffee monkeypatches each node's `compile` method
    # to append the node's .coffee line number as a block comment
    #   f/*@line: 3*/ = function(i/*@line: 3*/) { ...
    printLinenos()

    # recompile
    js       = compile(code, options)
    jslines  = js.split '\n'

    # a DebugCSFile object is used to store references to error line numbers
    # and to print the lines with errors
    csfile   = new DebugCSFile code

    # grab the stackline where the error actually occured
    for stackline in stack
      if stackline.indexOf('.coffee') > -1 then break

    #at Object.<anonymous> (.:3:1)
    inEval = stack[1].match /\(\.\:(\d*)\:\d*\)/
    if inEval then stackline = "/__commandline__.coffee:#{inEval[1]}:1"

    [match, file, lineno] = stackline.match /\/([A-Za-z0-9_\ \$\-\_\.]*\.(?:coffee|js))\:(\d*)\:\d/
    lineno = parseInt lineno

    ojsline = ojs.split('\n')[lineno - 1]

    # print the .js file's error information
    jsmsg = "in #{file.replace(/.coffee/, '.js')} on line #{lineno}\n"
    msg +=  "  #{jsmsg}  #{new Array(jsmsg.length).join('-')}\n"
    msg +=  "  > #{lineno} | #{ojsline}\n\n"

    # issue: for some reason, when recompiling, the jslines don't match...
    # I think the line where all the vars are declared doesn't get output again
    # (maybe something with scope.coffee?)
    jsline = jslines[ if options.bare then lineno - 2 else lineno - 3 ]

    # grab the CoffeeScript line numbers from the block comments in the .js file
    errlinenos = jsline.match /.*?\/\*\@line\:\ \d*\*\//g
    for errline in errlinenos
      [all,code,comment,cslineno] = errline.match /(.*?)(\/\*\@line\:\ (\d*)\*\/)/
      # add the error to the DebugCSFile
      csfile.error cslineno

    # print the .cs file's error information
    csmsg = "in #{file} on line #{cslineno}\n"
    msg +=  "  #{csmsg}  #{new Array(csmsg.length).join('-')}\n"

    # print all lines from the .cs file that contain an error, and
    # a few of the surrounding lines to give context
    # (error lines are indicated with a ">")
    msg += csfile.print() + '\n'

class DebugCSFile
  constructor: (code) ->
    @cslines = code.split '\n'
    @lines = {}

  error: (lineno) ->
    lineno = parseInt lineno
    @lines[lineno] = new DebugCSLine lineno, @cslines[lineno - 1], yes
    @contextualize lineno

  contextualize: (errlineno) ->
    for lineno in [errlineno-3...errlineno+3] when 0 < lineno < @cslines.length-1
      @lines[lineno] = new DebugCSLine lineno, @cslines[lineno - 1], no unless @lines[lineno]

  numlines: () ->
    max = 0
    for lineno of @lines
      max = Math.max parseInt(lineno),max
    max

  print: ->
    out = []
    length = String( @numlines() ).length
    out.push( line.print( length ) ) for lineno,line of @lines
    out.join('\n')

class DebugCSLine
  constructor: (lineno,@line,@isError) ->
    @lineno = String lineno

  print: (length) ->
    spaces = new Array( Math.max length + 2, 4 ).join(' ')[@lineno.length..]
    if @isError then spaces = spaces[1..]
    "#{spaces}#{if @isError then '>' else '' } #{@lineno} | #{@line}"

# Compile and evaluate a string of CoffeeScript (in a Node.js-like environment).
# The CoffeeScript REPL uses this to run the input.
exports.eval = (code, options = {}) ->
  return unless code = code.trim()
  sandbox = options.sandbox
  unless sandbox
    sandbox =
      require: require
      module : { exports: {} }
    sandbox[g] = global[g] for g in Object.getOwnPropertyNames global
    sandbox.global = sandbox
    sandbox.global.global = sandbox.global.root = sandbox.global.GLOBAL = sandbox
  sandbox.__filename = options.filename || 'eval'
  sandbox.__dirname  = path.dirname sandbox.__filename
  o = {}; o[k] = v for k, v of options
  o.bare = on # ensure return value
  js = compile "_=(#{code}\n)", o
  vm.runInNewContext js, sandbox, sandbox.__filename

# Instantiate a Lexer for our use here.
lexer = new Lexer

# The real Lexer produces a generic stream of tokens. This object provides a
# thin wrapper around it, compatible with the Jison API. We can then pass it
# directly as a "Jison lexer".
parser.lexer =
  lex: ->
    [tag, @yytext, @yylineno] = @tokens[@pos++] or ['']
    tag
  setInput: (@tokens) ->
    @pos = 0
  upcomingInput: ->
    ""

parser.yy = require './nodes'
