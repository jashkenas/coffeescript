# Importing
# ---------

unless window? or testingBrowser?

  test "javascript modules can be imported", ->
    magicVal = 1
    for module in 'import.js import2 .import2 import.extension.js import.unknownextension .coffee .coffee.md'.split ' '
      ok require("./importing/#{module}").value?() is magicVal, module

  test "coffeescript modules can be imported", ->
    magicVal = 2
    for module in '.import.coffee import.coffee import.extension.coffee'.split ' '
      ok require("./importing/#{module}").value?() is magicVal, module

  test "literate coffeescript modules can be imported", ->
    magicVal = 3
    # Leading space intentional to check for index.coffee.md
    for module in ' .import.coffee.md import.coffee.md import.litcoffee import.extension.coffee.md'.split ' '
      ok require("./importing/#{module}").value?() is magicVal, module
