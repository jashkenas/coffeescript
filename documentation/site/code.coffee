fs           = require 'fs'
_            = require 'underscore'

# Use CodeMirror in Node for syntax highlighting, per
# https://github.com/codemirror/CodeMirror/blob/master/bin/source-highlight
CodeMirror   = require 'codemirror/addon/runmode/runmode.node.js'
require 'codemirror/mode/coffeescript/coffeescript.js'
require 'codemirror/mode/javascript/javascript.js'

CoffeeScript = require '../../lib/coffeescript'


module.exports = ->
  (file, run = no) ->
    cs = fs.readFileSync "documentation/examples/#{file}.coffee", 'utf-8'
    js = CoffeeScript.compile cs, bare: yes # This is just the initial JavaScript output; it is replaced by dynamic compilation on changes of the CoffeeScript pane.
    render = _.template fs.readFileSync('documentation/site/code.html', 'utf-8')
    include = (file) -> fs.readFileSync("documentation/site/#{file}", 'utf-8')

    highlight = (language, code) ->
      # Adapted from https://github.com/codemirror/CodeMirror/blob/master/bin/source-highlight.
      html = ''
      curStyle = null
      accum = ''

      esc = (str) ->
        str.replace /[<&]/g, (ch) ->
          if ch is '&' then '&amp;' else '&lt;'

      flush = ->
        if curStyle
          html += "<span class=\"#{curStyle.replace /(^|\s+)/g, '$1cm-'}\">#{esc accum}</span>"
        else
          html += esc accum

      CodeMirror.runMode code, {name: language}, (text, style) ->
        if style isnt curStyle
          flush()
          curStyle = style
          accum = text
        else
          accum += text
      flush()

      html

    output = render {file, cs, js, highlight, include, run}
