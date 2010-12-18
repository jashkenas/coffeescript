fs            = require 'fs'
path          = require 'path'
{extend}      = require './lib/helpers'
CoffeeScript  = require './lib/coffee-script'
{spawn, exec} = require 'child_process'

# ANSI Terminal Colors.
bold  = '\033[0;1m'
red   = '\033[0;31m'
green = '\033[0;32m'
reset = '\033[0m'

# Built file header.
header = """
  /**
   * CoffeeScript Compiler v#{CoffeeScript.VERSION}
   * http://coffeescript.org
   *
   * Copyright 2010, Jeremy Ashkenas
   * Released under the MIT License
   */
"""

sources = [
  'src/coffee-script.coffee', 'src/grammar.coffee'
  'src/helpers.coffee', 'src/lexer.coffee', 'src/nodes.coffee'
  'src/rewriter.coffee', 'src/scope.coffee'
]

# Run a CoffeeScript through our node/coffee interpreter.
run = (args) ->
  proc =         spawn 'bin/coffee', args
  proc.stderr.on 'data', (buffer) -> console.log buffer.toString()
  proc.on        'exit', (status) -> process.exit(1) if status != 0

# Log a message with a color.
log = (message, color, explanation) ->
  console.log color + message + reset + ' ' + (explanation or '')

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'

task 'install', 'install CoffeeScript into /usr/local (or --prefix)', (options) ->
  base = options.prefix or '/usr/local'
  lib  = "#{base}/lib/coffee-script"
  bin  = "#{base}/bin"
  node = "~/.node_libraries/coffee-script"
  console.log   "Installing CoffeeScript to #{lib}"
  console.log   "Linking to #{node}"
  console.log   "Linking 'coffee' to #{bin}/coffee"
  exec([
    "mkdir -p #{lib} #{bin}"
    "cp -rf bin lib LICENSE README package.json src #{lib}"
    "ln -sf #{lib}/bin/coffee #{bin}/coffee"
    "ln -sf #{lib}/bin/cake #{bin}/cake"
    "mkdir -p ~/.node_libraries"
    "ln -sf #{lib}/lib #{node}"
  ].join(' && '), (err, stdout, stderr) ->
    if err then console.log stderr.trim() else log 'done', green
  )


task 'build', 'build the CoffeeScript language from source', ->
  files = fs.readdirSync 'src'
  files = ('src/' + file for file in files when file.match(/\.coffee$/))
  run ['-c', '-o', 'lib'].concat(files)


task 'build:full', 'rebuild the source twice, and run the tests', ->
  exec 'bin/cake build && bin/cake build && bin/cake test', (err, stdout, stderr) ->
    console.log stdout.trim() if stdout
    console.log stderr.trim() if stderr
    throw err    if err


task 'build:parser', 'rebuild the Jison parser (run build first)', ->
  extend global, require('util')
  require 'jison'
  parser = require('./lib/grammar').parser
  fs.writeFile 'lib/parser.js', parser.generate()


task 'build:ultraviolet', 'build and install the Ultraviolet syntax highlighter', ->
  exec 'plist2syntax ../coffee-script-tmbundle/Syntaxes/CoffeeScript.tmLanguage', (err) ->
    throw err if err
    exec 'sudo mv coffeescript.yaml /usr/local/lib/ruby/gems/1.8/gems/ultraviolet-0.10.2/syntax/coffeescript.syntax'


task 'build:browser', 'rebuild the merged script for inclusion in the browser', ->
  code = ''
  for name in ['helpers', 'rewriter', 'lexer', 'parser', 'scope', 'nodes', 'coffee-script', 'browser']
    code += """
      require['./#{name}'] = new function() {
        var exports = this;
        #{fs.readFileSync "lib/#{name}.js"}
      };
    """
  {parser, uglify} = require 'uglify-js'
  ast = parser.parse """
    this.CoffeeScript = function() {
      function require(path){ return require[path]; }
      #{code}
      return require['./coffee-script']
    }()
  """
  code = uglify.gen_code uglify.ast_squeeze uglify.ast_mangle ast, extra: yes
  fs.writeFileSync 'extras/coffee-script.js', header + '\n' + code
  invoke 'test:browser'


task 'doc:site', 'watch and continually rebuild the documentation for the website', ->
  exec 'rake doc', (err) ->
    throw err if err


task 'doc:source', 'rebuild the internal documentation', ->
  exec 'docco src/*.coffee && cp -rf docs documentation && rm -r docs', (err) ->
    throw err if err


task 'doc:underscore', 'rebuild the Underscore.coffee documentation page', ->
  exec 'docco examples/underscore.coffee && cp -rf docs documentation && rm -r docs', (err) ->
    throw err if err

task 'bench', 'quick benchmark of compilation time', ->
  {Rewriter} = require './lib/rewriter'
  co     = sources.map((name) -> fs.readFileSync name).join '\n'
  fmt    = (ms) -> " #{bold}#{ "   #{ms}".slice -4 }#{reset} ms"
  total  = 0
  now    = Date.now()
  time   = -> total += ms = -(now - now = Date.now()); fmt ms
  tokens = CoffeeScript.tokens co, rewrite: false
  console.log "Lex    #{time()} (#{tokens.length} tokens)"
  tokens = new Rewriter().rewrite tokens
  console.log "Rewrite#{time()} (#{tokens.length} tokens)"
  nodes  = CoffeeScript.nodes tokens
  console.log "Parse  #{time()}"
  js     = nodes.compile bare: true
  console.log "Compile#{time()} (#{js.length} chars)"
  console.log "total  #{ fmt total }"

task 'loc', 'count the lines of source code in the CoffeeScript compiler', ->
  exec "cat #{ sources.join(' ') } | grep -v '^\\( *#\\|\\s*$\\)' | wc -l | tr -s ' '", (err, stdout) ->
    console.log stdout.trim()


# Run the CoffeeScript test suite.
runTests = (CoffeeScript) ->
  startTime   = Date.now()
  currentFile = null
  passedTests = 0
  failures    = []

  # Mix in the assert module globally, to make it available for tests.
  for name, func of require 'assert'
    global[name] = ->
      passedTests += 1
      func arguments...

  # Convenience aliases.
  global.eq = global.strictEqual
  global.CoffeeScript = CoffeeScript

  # Our test helper function for delimiting different test cases.
  global.test = (description, fn) ->
    try
      fn()
    catch e
      e.message = description if description?
      e.source  = fn.toString() if fn.toString?
      failures.push file: currentFile, error: e

  # A recursive functional equivalence helper; uses egal for testing equivalence.
  # See http://wiki.ecmascript.org/doku.php?id=harmony:egal
  arrayEqual = (a, b) ->
    if a is b
      # 0 isnt -0
      a isnt 0 or 1/a is 1/b
    else if a instanceof Array and b instanceof Array
      return no unless a.length is b.length
      return no for el, idx in a when not arrayEqual el, b[idx]
      yes
    else
      # NaN is NaN
      a isnt a and b isnt b

  global.arrayEq = (a, b, msg) -> ok arrayEqual(a,b), msg

  # When all the tests have run, collect and print errors.
  # If a stacktrace is available, output the compiled function source.
  process.on 'exit', ->
    time = ((Date.now() - startTime) / 1000).toFixed(2)
    message = "passed #{passedTests} tests in #{time} seconds#{reset}"
    return log(message, green) unless failures.length
    log "failed #{failures.length} and #{message}", red
    for fail in failures
      {error, file}      = fail
      jsFile             = file.replace(/\.coffee$/,'.js')
      match              = error.stack?.match(new RegExp(fail.file+":(\\d+):(\\d+)"))
      [match, line, col] = match if match
      log "\n  #{error.message}", red if error.message
      log "  #{jsFile}: line #{line or 'unknown'}, column #{col or 'unknown'}", red
      console.log "  #{error.source}" if error.source

  # Run every test in the `test` folder, recording failures.
  fs.readdir 'test', (err, files) ->
    files.forEach (file) ->
      return unless file.match(/\.coffee$/i)
      fileName = path.join 'test', file
      fs.readFile fileName, (err, code) ->
        currentFile = fileName
        try
          CoffeeScript.run code.toString(), {fileName}
        catch e
          failures.push file: currentFile, error: e


task 'test', 'run the CoffeeScript language test suite', ->
  runTests CoffeeScript


task 'test:browser', 'run the test suite against the merged browser script', ->
  source = fs.readFileSync 'extras/coffee-script.js', 'utf-8'
  result = {}
  global.testingBrowser = yes
  (-> eval source).call result
  runTests result.CoffeeScript
