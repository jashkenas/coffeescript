fs = require 'fs'
path = require 'path'
vm = require 'vm'
nodeREPL = require 'repl'
process = require 'process'
CoffeeScript = require './'
{merge, updateSyntaxError} = require './helpers'

sawSIGINT = no
transpile = no

hint = '\n(Press Ctrl-V again to exit multi-line mode.)'

replDefaults =
  prompt: 'coffee> ',
  historyFile: do ->
    historyPath = process.env.XDG_CACHE_HOME or process.env.HOME
    path.join historyPath, '.coffee_history' if historyPath
  historyMaxInputSize: 10240
  eval: (input, context, filename, cb) ->
    # XXX: multiline hack.
    input = input.replace /\uFF00/g, '\n'
    # Node's REPL sends the input ending with a newline and then wrapped in
    # parens. Unwrap all that.
    input = input.replace /^\(([\s\S]*)\n\)$/m, '$1'
    # Node's REPL v6.9.1+ sends the input wrapped in a try/catch statement.
    # Unwrap that too.
    input = input.replace /^\s*try\s*{([\s\S]*)}\s*catch.*$/m, '$1'

    # Require AST nodes to do some AST manipulation.
    {Block, Assign, Value, Literal, Call, Code, Root} = require './nodes'

    try
      # Tokenize the clean input.
      tokens = CoffeeScript.tokens input
      # Filter out tokens generated just to hold comments.
      if tokens.length >= 2 and tokens[0].generated and
         tokens[0].comments?.length isnt 0 and "#{tokens[0][1]}" is '' and
         tokens[1][0] is 'TERMINATOR'
        tokens = tokens[2...]
      if tokens.length >= 1 and tokens[tokens.length - 1].generated and
         tokens[tokens.length - 1].comments?.length isnt 0 and "#{tokens[tokens.length - 1][1]}" is ''
        tokens.pop()
      # Collect referenced variable names just like in `CoffeeScript.compile`.
      referencedVars = (token[1] for token in tokens when token[0] is 'IDENTIFIER')
      # Generate the AST of the tokens.
      ast = CoffeeScript.nodes(tokens).body
      # Add assignment to `__` variable to force the input to be an expression.
      ast = new Block [new Assign (new Value new Literal '__'), ast, '=']
      # Wrap the expression in a closure to support top-level `await`.
      ast     = new Code [], ast
      isAsync = ast.isAsync
      # Invoke the wrapping closure.
      ast    = new Root new Block [new Call ast]
      js     = ast.compile {bare: yes, locals: Object.keys(context), referencedVars, sharedScope: yes}
      if transpile
        js = transpile.transpile(js, transpile.options).code
        # Strip `"use strict"`, to avoid an exception on assigning to
        # undeclared variable `__`.
        js = js.replace /^"use strict"|^'use strict'/, ''
      result = runInContext js, context, filename
      # Await an async result, if necessary.
      if isAsync
        result.then (resolvedResult) ->
          cb null, resolvedResult unless sawSIGINT
        sawSIGINT = no
      else
        cb null, result
    catch err
      # AST's `compile` does not add source code information to syntax errors.
      updateSyntaxError err, input
      cb err

runInContext = (js, context, filename) ->
  if context is global
    vm.runInThisContext js, filename
  else
    vm.runInContext js, context, filename

addMultilineHandler = (repl) ->
  {inputStream, outputStream} = repl
  # Node 0.11.12 changed API, prompt is now _prompt.
  origPrompt = repl._prompt ? repl.prompt

  multiline =
    showHint: true
    hint: hint
    enabled: off
    initialPrompt: origPrompt.replace /^[^> ]*/, (x) -> x.replace /./g, '-'
    prompt: origPrompt.replace /^[^> ]*>?/, (x) -> x.replace /./g, '.'
    buffer: ''

  # Proxy node's line listener
  nodeLineListener = repl.listeners('line')[0]
  repl.removeListener 'line', nodeLineListener
  repl.on 'line', (cmd) ->
    if multiline.enabled
      multiline.buffer += "#{cmd}\n"
      repl.setPrompt multiline.prompt
      repl.prompt true
    else
      repl.setPrompt origPrompt
      nodeLineListener cmd
    return

  # Handle Ctrl-v
  inputStream.on 'keypress', (char, key) ->
    return unless key and key.ctrl and not key.meta and not key.shift and key.name is 'v'
    if multiline.enabled
      # allow arbitrarily switching between modes any time before multiple lines are entered
      unless multiline.buffer.match /\n/
        multiline.enabled = not multiline.enabled
        repl.setPrompt origPrompt
        repl.prompt true
        return
      # no-op unless the current line is empty
      return if repl.line? and not repl.line.match /^\s*$/
      # eval, print, loop
      multiline.enabled = not multiline.enabled
      repl.line = ''
      repl.cursor = 0
      repl.output.cursorTo 0
      repl.output.clearLine 1
      # XXX: multiline hack
      multiline.buffer = multiline.buffer.replace /\n/g, '\uFF00'
      repl.emit 'line', multiline.buffer
      multiline.buffer = ''
    else
      if multiline.showHint
        console.log multiline.hint
        multiline.showHint = false
      multiline.enabled = not multiline.enabled
      repl.setPrompt multiline.initialPrompt
      repl.prompt true
    return

# Store and load command history from a file
addHistory = (repl, filename, maxSize) ->
  lastLine = null
  try
    # Get file info and at most maxSize of command history
    stat = fs.statSync filename
    size = Math.min maxSize, stat.size
    # Read last `size` bytes from the file
    readFd = fs.openSync filename, 'r'
    buffer = Buffer.alloc size
    fs.readSync readFd, buffer, 0, size, stat.size - size
    fs.closeSync readFd
    # Set the history on the interpreter
    repl.history = buffer.toString().split('\n').reverse()
    # If the history file was truncated we should pop off a potential partial line
    repl.history.pop() if stat.size > maxSize
    # Shift off the final blank newline
    repl.history.shift() if repl.history[0] is ''
    repl.historyIndex = -1
    lastLine = repl.history[0]

  fd = fs.openSync filename, 'a'

  repl.addListener 'line', (code) ->
    if code and code.length and code isnt '.history' and code isnt '.exit' and lastLine isnt code
      # Save the latest command in the file
      fs.writeSync fd, "#{code}\n"
      lastLine = code

  # XXX: The SIGINT event from REPLServer is undocumented, so this is a bit fragile
  repl.on 'SIGINT', -> sawSIGINT = yes
  repl.on 'exit', -> fs.closeSync fd

  # Add a command to show the history stack
  repl.commands[getCommandId(repl, 'history')] =
    help: 'Show command history'
    action: ->
      repl.outputStream.write "#{repl.history[..].reverse().join '\n'}\n"
      repl.displayPrompt()

getCommandId = (repl, commandName) ->
  # Node 0.11 changed API, a command such as '.help' is now stored as 'help'
  commandsHaveLeadingDot = repl.commands['.help']?
  if commandsHaveLeadingDot then ".#{commandName}" else commandName

module.exports =
  start: (opts = {}) ->
    [major, minor, build] = process.versions.node.split('.').map (n) -> parseInt(n, 10)

    if major < 6
      console.warn "Node 6+ required for CoffeeScript REPL"
      process.exit 1

    CoffeeScript.register()
    process.argv = ['coffee'].concat process.argv[2..]
    if opts.transpile
      transpile = {}
      try
        transpile.transpile = require('@babel/core').transform
      catch
        try
          transpile.transpile = require('babel-core').transform
        catch
          console.error '''
            To use --transpile with an interactive REPL, @babel/core must be installed either in the current folder or globally:
              npm install --save-dev @babel/core
            or
              npm install --global @babel/core
            And you must save options to configure Babel in one of the places it looks to find its options.
            See https://coffeescript.org/#transpilation
          '''
          process.exit 1
      transpile.options =
        filename: path.resolve process.cwd(), '<repl>'
      # Since the REPL compilation path is unique (in `eval` above), we need
      # another way to get the `options` object attached to a module so that
      # it knows later on whether it needs to be transpiled. In the case of
      # the REPL, the only applicable option is `transpile`.
      Module = require 'module'
      originalModuleLoad = Module::load
      Module::load = (filename) ->
        @options = transpile: transpile.options
        originalModuleLoad.call @, filename
    opts = merge replDefaults, opts
    repl = nodeREPL.start opts
    runInContext opts.prelude, repl.context, 'prelude' if opts.prelude
    repl.on 'exit', -> repl.outputStream.write '\n' if not repl.closed
    addMultilineHandler repl
    addHistory repl, opts.historyFile, opts.historyMaxInputSize if opts.historyFile
    # Adapt help inherited from the node REPL
    repl.commands[getCommandId(repl, 'load')].help = 'Load code from a file into this REPL session'
    repl
