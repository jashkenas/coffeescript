fs            = require 'fs'
helpers       = require './lib/helpers'
CoffeeScript  = require './lib/coffee-script'
{spawn, exec} = require 'child_process'
path          = require 'path'

# ANSI Terminal Colors.
red   = '\033[0;31m'
green = '\033[0;32m'
reset = '\033[0m'

# Run a CoffeeScript through our node/coffee interpreter.
run = (args) ->
  proc =         spawn 'bin/coffee', args
  proc.stderr.on 'data', (buffer) -> puts buffer.toString()
  proc.on        'exit', (status) -> process.exit(1) if status != 0

# Log a message with a color.
log = (message, color, explanation) ->
  puts color + message + reset + ' ' + (explanation or '')

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'

task 'install', 'install CoffeeScript into /usr/local (or --prefix)', (options) ->
  base = options.prefix or '/usr/local'
  lib  = "#{base}/lib/coffee-script"
  bin  = "#{base}/bin"
  node = "~/.node_libraries/coffee-script"
  puts   "Installing CoffeeScript to #{lib}"
  puts   "Linking to #{node}"
  puts   "Linking 'coffee' to #{bin}/coffee"
  exec([
    "mkdir -p #{lib} #{bin}"
    "cp -rf bin lib LICENSE README package.json src #{lib}"
    "ln -sf #{lib}/bin/coffee #{bin}/coffee"
    "ln -sf #{lib}/bin/cake #{bin}/cake"
    "mkdir -p ~/.node_libraries"
    "ln -sf #{lib}/lib #{node}"
  ].join(' && '), (err, stdout, stderr) ->
    if err then print stderr else log 'done', green
  )


task 'build', 'build the CoffeeScript language from source', ->
  files = fs.readdirSync 'src'
  files = 'src/' + file for file in files when file.match(/\.coffee$/)
  run ['-c', '-o', 'lib'].concat(files)


task 'build:full', 'rebuild the source twice, and run the tests', ->
  exec 'bin/cake build && bin/cake build && bin/cake test', (err, stdout, stderr) ->
    print stdout if stdout
    print stderr if stderr
    throw err    if err


task 'build:parser', 'rebuild the Jison parser (run build first)', ->
  require 'jison'
  parser = require('./lib/grammar').parser
  js = parser.generate()
  # TODO: Remove this when the Jison patch is released.
  js = js.replace 'if (require.main === module)', "if (typeof module !== 'undefined' && require.main === module)"
  fs.writeFile 'lib/parser.js', js


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

task 'bench', 'quick benchmark of compilation time (of everything in src)', ->
  exec 'time bin/coffee -p src/ > /dev/null', (err, stdout, stderr) ->
    print stderr

task 'loc', 'count the lines of source code in the CoffeeScript compiler', ->
  sources = ['src/coffee-script.coffee', 'src/grammar.coffee', 'src/helpers.coffee', 'src/lexer.coffee', 'src/nodes.coffee', 'src/rewriter.coffee', 'src/scope.coffee']
  exec "cat #{ sources.join(' ') } | grep -v '^\\( *#\\|\\s*$\\)' | wc -l | tr -s ' '", (err, stdout) ->
    print stdout


runTests = (CoffeeScript) ->
  startTime = Date.now()
  passedTests = failedTests = 0
  for all name, func of require 'assert'
    global[name] = -> ++passedTests; func arguments...
  global.eq = global.strictEqual
  global.CoffeeScript = CoffeeScript
  process.on 'exit', ->
    time = ((Date.now() - startTime) / 1000).toFixed(2)
    message = "passed #{passedTests} tests in #{time} seconds#{reset}"
    if failedTests
      log "failed #{failedTests} and #{message}", red
    else
      log message, green
  fs.readdir 'test', (err, files) ->
    files.forEach (file) ->
      return unless file.match(/\.coffee$/i)
      fileName = path.join 'test', file
      fs.readFile fileName, (err, code) ->
        try
          CoffeeScript.run code.toString(), {fileName}
        catch err
          failedTests += 1
          log "failed #{fileName}", red, '\n' + err.stack.toString()


task 'test', 'run the CoffeeScript language test suite', ->
  runTests CoffeeScript


task 'test:browser', 'run the test suite against the merged browser script', ->
  source = fs.readFileSync 'extras/coffee-script.js', 'utf-8'
  result = {}
  (-> eval source).call result
  runTests result.CoffeeScript
