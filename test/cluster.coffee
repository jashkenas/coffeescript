# Cluster Module
# ---------
# Currently `fork()` for `.coffee` files requires Node.js 0.9+
# Ignore the test when process.version does not match the requirement.
[major, minor, build] = process.version[1..].split('.').map (n) -> parseInt(n)
return if testingBrowser? or (major is 0 and minor < 9)

cluster = require 'cluster'

if cluster.isMaster
  test "#2737 - cluster module can spawn workers from a coffeescript process", ->
    cluster.once 'exit', (worker, code) ->
      eq code, 0

    cluster.fork()
else
  process.exit 0
