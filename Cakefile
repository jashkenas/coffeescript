fs: require 'fs'
coffee: require 'coffee-script'

# Run a CoffeeScript through our node/coffee interpreter.
run: (args) ->
  proc: process.createChildProcess 'bin/coffee', args
  proc.addListener 'error', (err) -> if err then puts err


task 'build', 'build the CoffeeScript language from source', ->
  fs.readdir('src').addCallback (files) ->
    files: 'src/' + file for file in files when file.match(/\.coffee$/)
    run ['-o', 'lib/coffee_script'].concat(files)


task 'build:parser', 'rebuild the Jison parser', ->
  invoke 'build:compiler'
  parser: require('grammar').parser
  js: parser.generate()
  parser_path: 'lib/coffee_script/parser.js'
  fs.open(parser_path, process.O_CREAT | process.O_WRONLY | process.O_TRUNC, parseInt('0755', 8)).addCallback (fd) ->
    fs.write(fd, js)


task 'build:ultraviolet', 'build and install the Ultraviolet syntax highlighter', ->
  exec('plist2syntax extras/CoffeeScript.tmbundle/Syntaxes/CoffeeScript.tmLanguage').addCallback ->
    exec 'sudo mv coffeescript.yaml /usr/local/lib/ruby/gems/1.8/gems/ultraviolet-0.10.2/syntax/coffeescript.syntax'


task 'build:underscore', 'rebuild the Underscore.coffee documentation page', ->
  exec 'uv -s coffeescript -t idle -h examples/underscore.coffee > documentation/underscore.html'

task 'test', 'run the CoffeeScript language test suite', ->
  process.mixin require 'assert'
  test_count: 0
  start_time: new Date()
  original_ok: ok
  process.mixin {
    ok: (args...) ->
      test_count += 1
      original_ok(args...)
  }
  process.addListener 'exit', ->
    time: ((new Date() - start_time) / 1000).toFixed(2)
    puts '\033[0;32mpassed ' + test_count + ' tests in ' + time + ' seconds\033[0m'
  fs.readdir('test').addCallback (files) ->
    for file in files
      fs.cat('test/' + file).addCallback (source) ->
        js: coffee.compile source
        process.compile js, file