fs:            require 'fs'
{helpers}:     require('./lib/helpers')
CoffeeScript:  require './lib/coffee-script'
{spawn, exec}: require('child_process')

# Run a CoffeeScript through our node/coffee interpreter.
run: (args) ->
  proc: spawn 'bin/coffee', args
  proc.stderr.addListener 'data', (buffer) -> puts buffer.toString()
  proc.addListener 'exit', (status) -> process.exit(1) if status != 0

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'

task 'install', 'install CoffeeScript into /usr/local (or --prefix)', (options) ->
  base: options.prefix or '/usr/local'
  lib:  "$base/lib/coffee-script"
  bin:  "$base/bin"
  exec([
    "mkdir -p $lib $bin"
    "cp -rf bin lib LICENSE README package.json src vendor $lib"
    "ln -sf $lib/bin/coffee $base/bin/coffee"
    "ln -sf $lib/bin/cake $base/bin/cake"
    "mkdir -p ~/.node_libraries"
    "ln -sf $lib/lib ~/.node_libraries/coffee-script"
  ].join(' && '), (err, stdout, stderr) ->
   if err then print stderr
  )


task 'build', 'build the CoffeeScript language from source', ->
  files: fs.readdirSync 'src'
  files: 'src/' + file for file in files when file.match(/\.coffee$/)
  run ['-c', '-o', 'lib'].concat(files)


task 'build:full', 'rebuild the source twice, and run the tests', ->
  exec 'bin/cake build && bin/cake build && bin/cake test', (err, stdout, stderr) ->
    print stdout if stdout
    print stderr if stderr
    throw err    if err


task 'build:parser', 'rebuild the Jison parser (run build first)', ->
  require.paths.unshift 'vendor/jison/lib'
  parser: require('./lib/grammar').parser
  js: parser.generate()
  parser_path: 'lib/parser.js'
  fs.writeFile parser_path, js


task 'build:ultraviolet', 'build and install the Ultraviolet syntax highlighter', ->
  exec 'plist2syntax ../coffee-script-tmbundle/Syntaxes/CoffeeScript.tmLanguage', (err) ->
    throw err if err
    exec 'sudo mv coffeescript.yaml /usr/local/lib/ruby/gems/1.8/gems/ultraviolet-0.10.2/syntax/coffeescript.syntax'


task 'build:browser', 'rebuild the merged script for inclusion in the browser', ->
  exec 'rake browser', (err) ->
    throw err if err


task 'doc:site', 'watch and continually rebuild the documentation for the website', ->
  exec 'rake doc'


task 'doc:source', 'rebuild the internal documentation', ->
  exec 'docco src/*.coffee && cp -rf docs documentation && rm -r docs', (err) ->
    throw err if err


task 'doc:underscore', 'rebuild the Underscore.coffee documentation page', ->
  exec 'docco examples/underscore.coffee && cp -rf docs documentation && rm -r docs', (err) ->
    throw err if err


task 'test', 'run the CoffeeScript language test suite', ->
  helpers.extend global, require 'assert'
  passed_tests: failed_tests: 0
  start_time:   new Date()
  original_ok:  ok
  helpers.extend global, {
    ok: (args...) -> passed_tests += 1; original_ok(args...)
    CoffeeScript: CoffeeScript
  }
  red: '\033[0;31m'
  green: '\033[0;32m'
  reset: '\033[0m'
  process.addListener 'exit', ->
    time: ((new Date() - start_time) / 1000).toFixed(2)
    message: "passed $passed_tests tests in $time seconds$reset"
    puts(if failed_tests then "${red}failed $failed_tests and $message" else "$green$message")
  fs.readdir 'test', (err, files) ->
    files.forEach (file) ->
      return unless file.match(/\.coffee$/i)
      source: path.join 'test', file
      fs.readFile source, (err, code) ->
        try
          CoffeeScript.run code, {source: source}
        catch err
          failed_tests += 1
          puts "${red}failed:${reset} $source"
          puts err.stack
