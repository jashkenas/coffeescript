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
    "mkdir -p ~/.nodeLibraries"
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
  parserPath: 'lib/parser.js'
  fs.writeFile parserPath, js


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


task 'loc', 'count the lines of source code in CoffeeScript', ->
  exec "cat src/*.coffee | grep -v '^\\( *#\\|\\s*$\\)' | wc -l | tr -s ' '", (err, stdout) ->
    print stdout


task 'test', 'run the CoffeeScript language test suite', ->
  helpers.extend global, require 'assert'
  passedTests: failedTests: 0
  startTime:   new Date()
  originalOk:  ok
  helpers.extend global, {
    ok: (args...) -> passedTests += 1; originalOk(args...)
    CoffeeScript: CoffeeScript
  }
  red: '\033[0;31m'
  green: '\033[0;32m'
  reset: '\033[0m'
  process.addListener 'exit', ->
    time: ((new Date() - startTime) / 1000).toFixed(2)
    message: "passed $passedTests tests in $time seconds$reset"
    puts(if failedTests then "${red}failed $failedTests and $message" else "$green$message")
  fs.readdir 'test', (err, files) ->
    files.forEach (file) ->
      return unless file.match(/\.coffee$/i)
      source: path.join 'test', file
      fs.readFile source, (err, code) ->
        try
          CoffeeScript.run code.toString(), {source: source}
        catch err
          failedTests += 1
          puts "${red}failed:${reset} $source"
          puts err.stack
