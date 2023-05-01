# CoffeeScript can be used both on the server, as a command-line compiler based
# on Node.js/V8, or to run CoffeeScript directly in the browser. This module
# contains the main entry functions for tokenizing, parsing, and compiling
# source CoffeeScript into JavaScript.

{Lexer}       = require './lexer'
{parser}      = require './parser'
helpers       = require './helpers'
SourceMap     = require './sourcemap'
# Require `package.json`, which is two levels above this file, as this file is
# evaluated from `lib/coffeescript`.
packageJson   = require '../../package.json'

# The current CoffeeScript version number.
exports.VERSION = packageJson.version

exports.FILE_EXTENSIONS = FILE_EXTENSIONS = ['.coffee', '.litcoffee', '.coffee.md']

# Expose helpers for testing.
exports.helpers = helpers

{getSourceMap, registerCompiled} = SourceMap
# This is exported to enable an external module to implement caching of
# sourcemaps. This is used only when `patchStackTrace` has been called to adjust
# stack traces for files with cached source maps.
exports.registerCompiled = registerCompiled

# Function that allows for btoa in both nodejs and the browser.
base64encode = (src) -> switch
  when typeof Buffer is 'function'
    Buffer.from(src).toString('base64')
  when typeof btoa is 'function'
    # The contents of a `<script>` block are encoded via UTF-16, so if any extended
    # characters are used in the block, btoa will fail as it maxes out at UTF-8.
    # See https://developer.mozilla.org/en-US/docs/Web/API/WindowBase64/Base64_encoding_and_decoding#The_Unicode_Problem
    # for the gory details, and for the solution implemented here.
    btoa encodeURIComponent(src).replace /%([0-9A-F]{2})/g, (match, p1) ->
      String.fromCharCode '0x' + p1
  else
    throw new Error('Unable to base64 encode inline sourcemap.')

# Function wrapper to add source file information to SyntaxErrors thrown by the
# lexer/parser/compiler.
withPrettyErrors = (fn) ->
  (code, options = {}) ->
    try
      fn.call @, code, options
    catch err
      throw err if typeof code isnt 'string' # Support `CoffeeScript.nodes(tokens)`.
      throw helpers.updateSyntaxError err, code, options.filename

# Compile CoffeeScript code to JavaScript, using the Coffee/Jison compiler.
#
# If `options.sourceMap` is specified, then `options.filename` must also be
# specified. All options that can be passed to `SourceMap#generate` may also
# be passed here.
#
# This returns a javascript string, unless `options.sourceMap` is passed,
# in which case this returns a `{js, v3SourceMap, sourceMap}`
# object, where sourceMap is a sourcemap.coffee#SourceMap object, handy for
# doing programmatic lookups.
exports.compile = compile = withPrettyErrors (code, options = {}) ->
  # Clone `options`, to avoid mutating the `options` object passed in.
  options = Object.assign {}, options

  generateSourceMap = options.sourceMap or options.inlineMap or not options.filename?
  filename = options.filename or helpers.anonymousFileName()

  checkShebangLine filename, code

  map = new SourceMap if generateSourceMap

  tokens = lexer.tokenize code, options

  # Pass a list of referenced variables, so that generated variables won’t get
  # the same name.
  options.referencedVars = (
    token[1] for token in tokens when token[0] is 'IDENTIFIER'
  )

  # Check for import or export; if found, force bare mode.
  unless options.bare? and options.bare is yes
    for token in tokens
      if token[0] in ['IMPORT', 'EXPORT']
        options.bare = yes
        break

  nodes = parser.parse tokens
  # If all that was requested was a POJO representation of the nodes, e.g.
  # the abstract syntax tree (AST), we can stop now and just return that
  # (after fixing the location data for the root/`File`»`Program` node,
  # which might’ve gotten misaligned from the original source due to the
  # `clean` function in the lexer).
  if options.ast
    nodes.allCommentTokens = helpers.extractAllCommentTokens tokens
    sourceCodeNumberOfLines = (code.match(/\r?\n/g) or '').length + 1
    sourceCodeLastLine = /.*$/.exec(code)[0] # `.*` matches all but line break characters.
    ast = nodes.ast options
    range = [0, code.length]
    ast.start = ast.program.start = range[0]
    ast.end = ast.program.end = range[1]
    ast.range = ast.program.range = range
    ast.loc.start = ast.program.loc.start = {line: 1, column: 0}
    ast.loc.end.line = ast.program.loc.end.line = sourceCodeNumberOfLines
    ast.loc.end.column = ast.program.loc.end.column = sourceCodeLastLine.length
    ast.tokens = tokens
    return ast

  fragments = nodes.compileToFragments options

  currentLine = 0
  currentLine += 1 if options.header
  currentLine += 1 if options.shiftLine
  currentColumn = 0
  js = ""
  for fragment in fragments
    # Update the sourcemap with data from each fragment.
    if generateSourceMap
      # Do not include empty, whitespace, or semicolon-only fragments.
      if fragment.locationData and not /^[;\s]*$/.test fragment.code
        map.add(
          [fragment.locationData.first_line, fragment.locationData.first_column]
          [currentLine, currentColumn]
          {noReplace: true})
      newLines = helpers.count fragment.code, "\n"
      currentLine += newLines
      if newLines
        currentColumn = fragment.code.length - (fragment.code.lastIndexOf("\n") + 1)
      else
        currentColumn += fragment.code.length

    # Copy the code from each fragment into the final JavaScript.
    js += fragment.code

  if options.header
    header = "Generated by CoffeeScript #{@VERSION}"
    js = "// #{header}\n#{js}"

  if generateSourceMap
    v3SourceMap = map.generate options, code

  if options.transpile
    if typeof options.transpile isnt 'object'
      # This only happens if run via the Node API and `transpile` is set to
      # something other than an object.
      throw new Error 'The transpile option must be given an object with options to pass to Babel'

    # Get the reference to Babel that we have been passed if this compiler
    # is run via the CLI or Node API.
    transpiler = options.transpile.transpile
    delete options.transpile.transpile

    transpilerOptions = Object.assign {}, options.transpile

    # See https://github.com/babel/babel/issues/827#issuecomment-77573107:
    # Babel can take a v3 source map object as input in `inputSourceMap`
    # and it will return an *updated* v3 source map object in its output.
    if v3SourceMap and not transpilerOptions.inputSourceMap?
      transpilerOptions.inputSourceMap = v3SourceMap
    transpilerOutput = transpiler js, transpilerOptions
    js = transpilerOutput.code
    if v3SourceMap and transpilerOutput.map
      v3SourceMap = transpilerOutput.map

  if options.inlineMap
    encoded = base64encode JSON.stringify v3SourceMap
    sourceMapDataURI = "//# sourceMappingURL=data:application/json;base64,#{encoded}"
    sourceURL = "//# sourceURL=#{filename}"
    js = "#{js}\n#{sourceMapDataURI}\n#{sourceURL}"

  registerCompiled filename, code, map

  if options.sourceMap
    {
      js
      sourceMap: map
      v3SourceMap: JSON.stringify v3SourceMap, null, 2
    }
  else
    js

# Tokenize a string of CoffeeScript code, and return the array of tokens.
exports.tokens = withPrettyErrors (code, options) ->
  lexer.tokenize code, options

# Parse a string of CoffeeScript code or an array of lexed tokens, and
# return the AST. You can then compile it by calling `.compile()` on the root,
# or traverse it by using `.traverseChildren()` with a callback.
exports.nodes = withPrettyErrors (source, options) ->
  source = lexer.tokenize source, options if typeof source is 'string'
  parser.parse source

# This file used to export these methods; leave stubs that throw warnings
# instead. These methods have been moved into `index.coffee` to provide
# separate entrypoints for Node and non-Node environments, so that static
# analysis tools don’t choke on Node packages when compiling for a non-Node
# environment.
exports.run = exports.eval = exports.register = ->
  throw new Error 'require index.coffee, not this file'

# Instantiate a Lexer for our use here.
lexer = new Lexer

# The real Lexer produces a generic stream of tokens. This object provides a
# thin wrapper around it, compatible with the Jison API. We can then pass it
# directly as a “Jison lexer.”
parser.lexer =
  yylloc:
    range: []
  options:
    ranges: yes
  lex: ->
    token = parser.tokens[@pos++]
    if token
      [tag, @yytext, @yylloc] = token
      parser.errorToken = token.origin or token
      @yylineno = @yylloc.first_line
    else
      tag = ''
    tag
  setInput: (tokens) ->
    parser.tokens = tokens
    @pos = 0
  upcomingInput: -> ''

# Make all the AST nodes visible to the parser.
parser.yy = require './nodes'

# Override Jison's default error handling function.
parser.yy.parseError = (message, {token}) ->
  # Disregard Jison's message, it contains redundant line number information.
  # Disregard the token, we take its value directly from the lexer in case
  # the error is caused by a generated token which might refer to its origin.
  {errorToken, tokens} = parser
  [errorTag, errorText, errorLoc] = errorToken

  errorText = switch
    when errorToken is tokens[tokens.length - 1]
      'end of input'
    when errorTag in ['INDENT', 'OUTDENT']
      'indentation'
    when errorTag in ['IDENTIFIER', 'NUMBER', 'INFINITY', 'STRING', 'STRING_START', 'REGEX', 'REGEX_START']
      errorTag.replace(/_START$/, '').toLowerCase()
    else
      helpers.nameWhitespaceCharacter errorText

  # The second argument has a `loc` property, which should have the location
  # data for this token. Unfortunately, Jison seems to send an outdated `loc`
  # (from the previous token), so we take the location information directly
  # from the lexer.
  helpers.throwSyntaxError "unexpected #{errorText}", errorLoc

exports.patchStackTrace = ->
  # Check if Node's built-in source map stack trace transformations are enabled.
  nodeSourceMapsSupportEnabled = process? and (
    process.execArgv.includes('--enable-source-maps') or
    process.env.NODE_OPTIONS?.includes('--enable-source-maps')
  )

  # Skip if node source maps are already enabled,
  # or Error.prepareStackTrace is already defined.
  return if Error.prepareStackTrace or nodeSourceMapsSupportEnabled

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

  getSourceMapping = (filename, line, column) ->
    sourceMap = getSourceMap filename, line, column

    answer = sourceMap.sourceLocation [line - 1, column - 1] if sourceMap?
    if answer? then [answer[0] + 1, answer[1] + 1] else null

  # Based on [michaelficarra/CoffeeScriptRedux](http://goo.gl/ZTx1p)
  # NodeJS / V8 have no support for transforming positions in stack traces using
  # sourceMap, so we must monkey-patch Error to display CoffeeScript source
  # positions.
  Error.prepareStackTrace = (err, stack) ->
    frames = for frame in stack
      # Don’t display stack frames deeper than `CoffeeScript.run`.
      break if frame.getFunction() is exports.run
      "    at #{formatSourcePosition frame, getSourceMapping}"

    "#{err.toString()}\n#{frames.join '\n'}\n"

checkShebangLine = (file, input) ->
  firstLine = input.split(/$/m)[0]
  rest = firstLine?.match(/^#!\s*([^\s]+\s*)(.*)/)
  args = rest?[2]?.split(/\s/).filter (s) -> s isnt ''
  if args?.length > 1
    console.error '''
      The script to be run begins with a shebang line with more than one
      argument. This script will fail on platforms such as Linux which only
      allow a single argument.
    '''
    console.error "The shebang line was: '#{firstLine}' in file '#{file}'"
    console.error "The arguments were: #{JSON.stringify args}"
