# Contributed by Jason Huggins

process.mixin require 'sys'
http: require 'http'

server: http.createServer (req, res) ->
  res.writeHeader 200, {'Content-Type': 'text/plain'}
  res.write 'Hello, World!'
  res.close()

server.listen 3000

puts "Server running at http://localhost:3000/"
