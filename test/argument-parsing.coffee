p = (desc, obj) -> console.error "#{desc}: #{JSON.stringify obj}"

# console.error (k for k of CoffeeScript)

throw new Error "?"

optionParser = CoffeeScript.command.buildCSOptionParser()

test "combined options are still split after initial file name", ->
  args = []
