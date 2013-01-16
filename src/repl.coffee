vm = require 'vm'
repl = require 'repl'
CoffeeScript = require './coffee-script'
{merge} = require './helpers'

replDefaults =
  prompt: 'coffee> ',
  eval: (code, context, file, cb) ->
    try
      code = '' if /^\(\s+\)$/.test code # Empty command won't parse
      code = CoffeeScript.compile(code, {filename: file, bare: true})
      cb(null, vm.runInContext(code, context, file))
    catch err
      cb(err)

module.exports =
  start: (opts = {}) ->
    repl.start merge(replDefaults, opts)
