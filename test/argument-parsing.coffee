p = (desc, obj) -> console.error "#{desc}: #{JSON.stringify obj}"

{buildCSOptionParser} = require '../src/command'

optionParser = buildCSOptionParser()

test "combined options are still split after initial file name", ->
  args = []
