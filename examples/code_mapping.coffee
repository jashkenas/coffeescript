PORT = 4944

http = require 'http'
fs = require 'fs'
coffee = require '../'

secret = Math.random().toString(36).slice(2)
#secret = 'foo'

console.log "Use http://localhost:#{PORT}/#{secret}/home/user/whatever.coffee to view compilation stuff"

http.createServer (req, res) ->
  path = req.url.slice 1
  if (path.indexOf secret) isnt 0
    return res.end 'wrong secret'
  path = path.slice secret.length
  fs.readFile path, 'utf8', (err, coffeecode) ->
    if err
      return res.end err.stack || err
    try
      jscode = coffee.compile coffeecode
    catch err
      return res.end err.stack || err
    
    getNode = (i) ->
      j = i
      j-- while j > 0 and not jscode.sources[j]?
      jscode.sources[j]
    
    locationString = (node) ->
      return if not node?.location?
      node.constructor.name + ' at ' + node.location.toString()
    
    console.log "rendering code for #{path}..."
    
    res.writeHead 200, {'Content-Type': 'text/html'}
    res.end """
      <html>
        <head>
          <script>
            window.onload = function() {
              [].slice.call(document.getElementsByClassName('jschar')).forEach(function(jschar) {
                jschar.addEventListener('click', function() {
                  alert(jschar.getAttribute('data-text'))
                }, false)
              })
            }
          </script>
        </head>
        <body style=\"white-space: pre; font-family: monospace\">#{
          lastloc = null
          (for char, i in jscode.value
            location = locationString getNode i
            result = if location
              "<span class=\"jschar\" #{[if location isnt lastloc then 'style="background-color: green"']} data-text=\"#{location}\">#{char}</span>"
            else
              "<span style=\"background-color: red\">#{char}</span>"
            lastloc = location
            result
          ).join('')
        }</body>
      </html>
    """
.listen PORT
