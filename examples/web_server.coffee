# Contributed by Jason Huggins

sys  = require 'sys'
http = require 'http'

server = http.createServer (req, res) ->
  res.writeHeader 200, 'Content-Type': 'text/plain'
  res.write 'Hello, World!'
  res.end()

server.listen 3000

sys.puts "Server running at http://localhost:3000/"
