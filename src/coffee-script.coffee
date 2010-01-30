# Executes the `coffee` Ruby program to convert from CoffeeScript to JavaScript.

sys: require('sys')

exports.compile: (code, callback) ->
  js: ''
  coffee: process.createChildProcess 'coffee', ['--eval', '--no-wrap', '--globals']
  coffee.addListener 'output', (results) ->
    js += results if results?
  coffee.addListener 'exit', ->
    callback(js)
  coffee.write(code)
  coffee.close()


