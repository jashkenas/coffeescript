# Contributed by Jason Huggins

http: require 'http'

server: http.createServer (req, res) ->
  res.sendHeader 200, {'Content-Type': 'text/plain'}
  res.sendBody 'Hello, World!'
  res.finish()

server.listen 3000

puts "Server running at http://localhost:3000/"