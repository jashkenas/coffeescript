fs           = require 'fs'
_            = require 'underscore'
CoffeeScript = require '../../lib/coffeescript'


module.exports = ->
  (file, run = no) ->
    cs = fs.readFileSync "documentation/examples/#{file}.coffee", 'utf-8'
    js = CoffeeScript.compile cs, bare: yes # This is just the initial JavaScript output; it is replaced by dynamic compilation on changes of the CoffeeScript pane
    render = _.template fs.readFileSync('documentation/v2/code.html', 'utf-8')
    output = render {file, cs, js, run}
