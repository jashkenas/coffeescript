fs = require 'fs'
path = require 'path'
vm = require 'vm'
nodeREPL = require 'repl'
CoffeeScript = require './coffee-script'
{merge, updateSyntaxError} = require './helpers'

replDefaults =
  prompt: 'coffee> ',
  historyFile: path.join process.env.HOME, '.coffee_history' if process.env.HOME
  historyMaxInputSize: 10240
  eval: (input, context, filename, cb) ->
    # XXX: multiline hack.
    input = input.replace /\uFF00/g, '\n'
    # Node's REPL sends the input ending with a newline and then wrapped in
    # parens. Unwrap all that.
    input = input.replace /^\(([\s\S]*)\n\)$/m, '$1'

    # Require AST nodes to do some AST manipulation.
    {Block, Assign, Value, Literal} = require './nodes'

    try
      # Tokenize the clean input.
      tokens = CoffeeScript.tokens input
      # Collect referenced variable names just like in `CoffeeScript.compile`.
      referencedVars = (
        token[1] for token in tokens when token.variable
      )
      # Generate the AST of the tokens.
      ast = CoffeeScript.nodes tokens
      # Add assignment to `_` variable to force the input to be an expression.
      ast = new Block [
        new Assign (new Value new Literal '_'), ast, '='
      ]
      js = ast.compile {bare: yes, locals: Object.keys(context), referencedVars}
      cb null, runInContext js, context, filename
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
  {rli, inputStream, outputStream} = repl
  # Node 0.11.12 changed API, prompt is now _prompt.
  origPrompt = repl._prompt ? repl.prompt

  multiline =
    enabled: off
    initialPrompt: origPrompt.replace /^[^> ]*/, (x) -> x.replace /./g, '-'
    prompt: origPrompt.replace /^[^> ]*>?/, (x) -> x.replace /./g, '.'
    buffer: ''

  # Proxy node's line listener
  nodeLineListener = rli.listeners('line')[0]
  rli.removeListener 'line', nodeLineListener
  rli.on 'line', (cmd) ->
    if multiline.enabled
      multiline.buffer += "#{cmd}\n"
      rli.setPrompt multiline.prompt
      rli.prompt true
    else
      rli.setPrompt origPrompt
      nodeLineListener cmd
    return

  # Handle Ctrl-v
  inputStream.on 'keypress', (char, key) ->
    return unless key and key.ctrl and not key.meta and not key.shift and key.name is 'v'
    if multiline.enabled
      # allow arbitrarily switching between modes any time before multiple lines are entered
      unless multiline.buffer.match /\n/
        multiline.enabled = not multiline.enabled
        rli.setPrompt origPrompt
        rli.prompt true
        return
      # no-op unless the current line is empty
      return if rli.line? and not rli.line.match /^\s*$/
      # eval, print, loop
      multiline.enabled = not multiline.enabled
      rli.line = ''
      rli.cursor = 0
      rli.output.cursorTo 0
      rli.output.clearLine 1
      # XXX: multiline hack
      multiline.buffer = multiline.buffer.replace /\n/g, '\uFF00'
      rli.emit 'line', multiline.buffer
      multiline.buffer = ''
    else
      multiline.enabled = not multiline.enabled
      rli.setPrompt multiline.initialPrompt
      rli.prompt true
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
    buffer = new Buffer(size)
    fs.readSync readFd, buffer, 0, size, stat.size - size
    fs.close readFd
    # Set the history on the interpreter
    repl.rli.history = buffer.toString().split('\n').reverse()
    # If the history file was truncated we should pop off a potential partial line
    repl.rli.history.pop() if stat.size > maxSize
    # Shift off the final blank newline
    repl.rli.history.shift() if repl.rli.history[0] is ''
    repl.rli.historyIndex = -1
    lastLine = repl.rli.history[0]

  fd = fs.openSync filename, 'a'

  repl.rli.addListener 'line', (code) ->
    if code and code.length and code isnt '.history' and lastLine isnt code
      # Save the latest command in the file
      fs.write fd, "#{code}\n"
      lastLine = code

  repl.on 'exit', -> fs.close fd

  # Add a command to show the history stack
  repl.commands[getCommandId(repl, 'history')] =
    help: 'Show command history'
    action: ->
      repl.outputStream.write "#{repl.rli.history[..].reverse().join '\n'}\n"
      repl.displayPrompt()

getCommandId = (repl, commandName) ->
  # Node 0.11 changed API, a command such as '.help' is now stored as 'help'
  commandsHaveLeadingDot = repl.commands['.help']?
  if commandsHaveLeadingDot then ".#{commandName}" else commandName

module.exports =
  start: (opts = {}) ->
    [major, minor, build] = process.versions.node.split('.').map (n) -> parseInt(n)

    if major is 0 and minor < 8
      console.warn "Node 0.8.0+ required for CoffeeScript REPL"
      process.exit 1

    CoffeeScript.register()
    process.argv = ['coffee'].concat process.argv[2..]
    opts = merge replDefaults, opts
    repl = nodeREPL.start opts
    runInContext opts.prelude, repl.context, 'prelude' if opts.prelude
    repl.on 'exit', -> repl.outputStream.write '\n' if not repl.rli.closed
    addMultilineHandler repl
    addHistory repl, opts.historyFile, opts.historyMaxInputSize if opts.historyFile
    # Adapt help inherited from the node REPL
    repl.commands[getCommandId(repl, 'load')].help = 'Load code from a file into this REPL session'
    repl
