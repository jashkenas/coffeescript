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
      # Generate the AST of the clean input.
      ast = CoffeeScript.nodes input
      # Add assignment to `_` variable to force the input to be an expression.
      ast = new Block [
        new Assign (new Value new Literal '_'), ast, '='
      ]
      js = ast.compile bare: yes, locals: Object.keys(context)
      result = if context is global
        vm.runInThisContext js, filename 
      else
        vm.runInContext js, context, filename
      cb null, result
    catch err
      # AST's `compile` does not add source code information to syntax errors.
      updateSyntaxError err, input
      cb err

addMultilineHandler = (repl) ->
  {rli, inputStream, outputStream} = repl

  multiline =
    enabled: off
    initialPrompt: repl.prompt.replace /^[^> ]*/, (x) -> x.replace /./g, '-'
    prompt: repl.prompt.replace /^[^> ]*>?/, (x) -> x.replace /./g, '.'
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
      nodeLineListener cmd
    return

  # Handle Ctrl-v
  inputStream.on 'keypress', (char, key) ->
    return unless key and key.ctrl and not key.meta and not key.shift and key.name is 'v'
    if multiline.enabled
      # allow arbitrarily switching between modes any time before multiple lines are entered
      unless multiline.buffer.match /\n/
        multiline.enabled = not multiline.enabled
        rli.setPrompt repl.prompt
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

  repl.rli.on 'exit', -> fs.close fd

  # Add a command to show the history stack
  repl.commands['.history'] =
    help: 'Show command history'
    action: ->
      repl.outputStream.write "#{repl.rli.history[..].reverse().join '\n'}\n"
      repl.displayPrompt()

module.exports =
  start: (opts = {}) ->
    [major, minor, build] = process.versions.node.split('.').map (n) -> parseInt(n)

    if major is 0 and minor < 8
      console.warn "Node 0.8.0+ required for CoffeeScript REPL"
      process.exit 1

    opts = merge replDefaults, opts
    repl = nodeREPL.start opts
    repl.on 'exit', -> repl.outputStream.write '\n'
    addMultilineHandler repl
    addHistory repl, opts.historyFile, opts.historyMaxInputSize if opts.historyFile
    repl
