# After wycats' http://yehudakatz.com/2010/02/07/the-building-blocks-of-ruby/

# Sinatra.
get '/hello', ->
  'Hello World'


# Append.
append = (location, data) ->
  path = new Pathname location
  throw new Error("Location does not exist") unless path.exists()

  File.open path, 'a', (file) ->
    file.puts YAML.dump data

  data


# Rubinius' File.open implementation.
File.open = (path, mode, block) ->
  io = new File path, mode

  return io unless block

  try
    block io
  finally
    io.close() unless io.closed()


# Write.
write = (location, data) ->
  path = new Pathname location
  raise "Location does not exist" unless path.exists()

  File.open path, 'w', (file) ->
    return false if Digest.MD5.hexdigest(file.read()) is data.hash()
    file.puts YAML.dump data
    true


# Rails' respond_to.
index = ->
  people = Person.find 'all'

  respond_to (format) ->
    format.html()
    format.xml -> render xml: people.xml()


# Synchronization.
synchronize = (block) ->
  lock()
  try block() finally unlock()
