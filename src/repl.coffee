vm = require 'vm'
nodeREPL = require 'repl'
CoffeeScript = require './coffee-script'
{merge} = require './helpers'

replDefaults =
  prompt: 'coffee> ',
  eval: (input, context, filename, cb) ->
    try
      return cb null if /^\(\s+\)$/.test input # Empty command
      # TODO: pass in-scope vars and avoid accidentally shadowing them by omitting those declarations
      js = CoffeeScript.compile input, {filename, bare: yes}
      cb null, vm.runInContext js, context, filename
    catch err
      cb err

# TODO: how to test?
addMultilineHandler = (repl) ->
  {rli, inputStream, outputStream} = repl

  multiline =
    enabled: off
    initialPrompt: '------> '
    prompt: '......> '
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
      nodeLineListener(cmd)
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
      return unless rli.line.match /^\s*$/
      # eval, print, loop
      multiline.enabled = not multiline.enabled
      rli.line = ''
      rli.cursor = 0
      rli.output.cursorTo 0
      rli.output.clearLine 1
      rli.emit 'line', multiline.buffer
      multiline.buffer = ''
    else
      multiline.enabled = not multiline.enabled
      rli.setPrompt multiline.initialPrompt
      rli.prompt true
    return

module.exports =
  start: (opts = {}) ->
    opts = merge replDefaults, opts
    repl = nodeREPL.start opts
    repl.on 'exit', -> repl.outputStream.write '\n'
    addMultilineHandler repl
    repl
