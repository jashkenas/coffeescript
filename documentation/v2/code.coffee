fs           = require 'fs'
_            = require 'underscore'
hljs         = require 'highlight.js'
CoffeeScript = require '../../lib/coffeescript'


module.exports = ->
  (file, run = no) ->
    cs = fs.readFileSync "documentation/examples/#{file}.coffee", 'utf-8'
    js = CoffeeScript.compile cs, bare: yes # This is just the initial JavaScript output; it is replaced by dynamic compilation on changes of the CoffeeScript pane
    render = _.template fs.readFileSync('documentation/v2/code.html', 'utf-8')
    highlight = (language, code) ->
      html = hljs.highlight(language, code).value
      if language is 'coffeescript'
        html = html.replace /-&gt;/g, '<span class="operator">-&gt;</span>'
        html = html.replace /\=&gt;/g, '<span class="operator">=&gt;</span>'
      html
    output = render {highlight, file, cs, js, run}
