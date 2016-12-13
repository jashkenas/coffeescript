fs           = require 'fs'
CoffeeScript = require '../../lib/coffee-script'


module.exports = ->
  (file, executable = no, showLoad = yes) ->
    cs = fs.readFileSync "documentation/examples/#{file}.coffee", 'utf-8'
    js = CoffeeScript.compile cs, bare: yes
    """
      <aside class="container-fluid">
        <div class="row">
          <div class="col-md-6">
            <textarea class="coffee-example">#{cs}</textarea>
          </div>
          <div class="col-md-6">
            <textarea class="javascript-output">#{js}</textarea>
          </div>
        </div>
      </aside>
    """
