# Importing
# ---------

unless window? or testingBrowser?
  test "coffeescript modules can be imported and executed", ->

    magicKey = __filename
    magicValue = 0xFFFF

    if global[magicKey]?
      if exports?
        local = magicValue
        exports.method = -> local
    else
      global[magicKey] = {}
      if require?.extensions?
        ok require(__filename).method() is magicValue
      delete global[magicKey]

  test "javascript modules can be imported", ->
    magicVal = 1
    for module in 'test.js test2 .test2 test.extension.js test.unknownextension .coffee .coffee.md'.split ' '
      ok require("./importing/#{module}").value?() is magicVal, module

  test "coffeescript modules can be imported", ->
    magicVal = 2
    for module in '.test.coffee test.coffee test.extension.coffee'.split ' '
      ok require("./importing/#{module}").value?() is magicVal, module

  test "literate coffeescript modules can be imported", ->
    magicVal = 3
    # Leading space intentional to check for index.coffee.md
    for module in ' .test.coffee.md test.coffee.md test.litcoffee test.extension.coffee.md'.split ' '
      ok require("./importing/#{module}").value?() is magicVal, module
