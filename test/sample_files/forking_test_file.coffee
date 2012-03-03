fork = require('child_process').fork

if process.send?
  process.exit()
else
  child = fork __filename
  child.on "exit", (code) ->
    process.exit code
