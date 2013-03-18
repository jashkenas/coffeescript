# Cluster Module
# ---------

return if testingBrowser?

cluster = require 'cluster'

if cluster.isMaster
  test "#2737 - cluster module can spawn workers from a coffeescript process", ->
    cluster.once 'exit', (worker, code) ->
      eq code, 0

    cluster.fork()
else
  process.exit 0
