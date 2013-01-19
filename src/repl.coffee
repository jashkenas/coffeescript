vm = require 'vm'
nodeREPL = require 'repl'
CoffeeScript = require './coffee-script'
{merge} = require './helpers'

replDefaults =
  prompt: 'coffee> ',
  eval: (code, context, file, cb) ->
    try
      return cb(null) if /^\(\s+\)$/.test code # Empty command
      code = code.replace /子/mg, '\n' # Temporary hack, see TODO below
      code = CoffeeScript.compile(code, {filename: file, bare: true})
      cb(null, vm.runInContext(code, context, file))
    catch err
      cb(err)

# TODO: how to test?
addMultilineHandler = (repl) ->
  {rli, inputStream, outputStream} = repl

  multiline = 
    enabled: off
    prompt: new Array(repl.prompt.length).join('.') + ' '
    buffer: ''

  # Proxy node's line listener
  nodeLineListener = rli.listeners('line')[0]
  rli.removeListener 'line', nodeLineListener
  rli.on 'line', (cmd) ->
    if multiline.enabled is on
      multiline.buffer += "#{cmd}\n"
      rli.prompt true
    else
      nodeLineListener(cmd)

  # Handle Ctrl-v
  inputStream.on 'keypress', (char, key) ->
    return unless key and key.ctrl and not key.meta and not key.shift and key.name is 'v'
    multiline.enabled = !multiline.enabled
    if multiline.enabled is off
      unless multiline.buffer.match /\n/
        rli.setPrompt repl.prompt
        rli.prompt true
        return
      # TODO: how to encode line breaks so the node repl will pass the complete multiline to our eval?
      multiline.buffer = multiline.buffer.replace /\n/mg, '子'
      rli.emit 'line', multiline.buffer
      multiline.buffer = ''
    else
      rli.setPrompt multiline.prompt
      rli.prompt true

module.exports =
  start: (opts = {}) ->
    opts = merge(replDefaults, opts)
    repl = nodeREPL.start opts
    addMultilineHandler(repl)
    repl