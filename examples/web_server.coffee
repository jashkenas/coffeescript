# Contributed by Jason Huggins

http = require 'http'

server = http.createServer (req, res) ->
  res.writeHeader 200, 'Content-Type': 'text/plain'
  res.write 'Hello, World!'
  res.end()

server.listen 3000

console.log "Server running at http://localhost:3000/"
