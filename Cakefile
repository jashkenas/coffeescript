fs            = require 'fs'
path          = require 'path'
CoffeeScript  = require './lib/coffee-script'
{spawn, exec} = require 'child_process'
helpers       = require './lib/coffee-script/helpers'

# ANSI Terminal Colors.
bold = red = green = reset = ''
unless process.env.NODE_DISABLE_COLORS
  bold  = '\x1B[0;1m'
  red   = '\x1B[0;31m'
  green = '\x1B[0;32m'
  reset = '\x1B[0m'

# Built file header.
header = """
  /**
   * CoffeeScript Compiler v#{CoffeeScript.VERSION}
   * http://coffeescript.org
   *
   * Copyright 2011, Jeremy Ashkenas
   * Released under the MIT License
   */
"""

# Build the CoffeeScript language from source.
build = (cb) ->
  files = fs.readdirSync 'src'
  files = ('src/' + file for file in files when file.match(/\.(lit)?coffee$/))
  run ['-c', '-o', 'lib/coffee-script'].concat(files), cb

# Run a CoffeeScript through our node/coffee interpreter.
run = (args, cb) ->
  proc =         spawn 'node', ['bin/coffee'].concat(args)
  proc.stderr.on 'data', (buffer) -> console.log buffer.toString()
  proc.on        'exit', (status) ->
    process.exit(1) if status != 0
    cb() if typeof cb is 'function'

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
    "ln -sfn #{lib}/bin/coffee #{bin}/coffee"
    "ln -sfn #{lib}/bin/cake #{bin}/cake"
    "mkdir -p ~/.node_libraries"
    "ln -sfn #{lib}/lib/coffee-script #{node}"
  ].join(' && '), (err, stdout, stderr) ->
    if err then console.log stderr.trim() else log 'done', green
  )


task 'build', 'build the CoffeeScript language from source', build

task 'build:full', 'rebuild the source twice, and run the tests', ->
  build ->
    build ->
      csPath = './lib/coffee-script'
      csDir  = path.dirname require.resolve csPath

      for mod of require.cache when csDir is mod[0 ... csDir.length]
        delete require.cache[mod]

      unless runTests require csPath
        process.exit 1


task 'build:parser', 'rebuild the Jison parser (run build first)', ->
  helpers.extend global, require('util')
  require 'jison'
  parser = require('./lib/coffee-script/grammar').parser
  fs.writeFile 'lib/coffee-script/parser.js', parser.generate()

task 'build:browser', 'rebuild the merged script for inclusion in the browser', ->
  code = ''
  for name in ['helpers', 'rewriter', 'lexer', 'parser', 'scope', 'nodes', 'sourcemap', 'coffee-script', 'browser']
    code += """
      require['./#{name}'] = (function() {
        var exports = {}, module = {exports: exports};
        #{fs.readFileSync "lib/coffee-script/#{name}.js"}
        return module.exports;
      })();
    """
  code = """
    (function(root) {
      var CoffeeScript = function() {
        function require(path){ return require[path]; }
        #{code}
        return require['./coffee-script'];
      }();

      if (typeof define === 'function' && define.amd) {
        define(function() { return CoffeeScript; });
      } else {
        root.CoffeeScript = CoffeeScript;
      }
    }(this));
  """
  unless process.env.MINIFY is 'false'
    {code} = require('uglify-js').minify code, fromString: true
  fs.writeFileSync 'extras/coffee-script.js', header + '\n' + code
  console.log "built ... running browser tests:"
  invoke 'test:browser'


task 'doc:site', 'build the documentation for the website', ->
  source = 'documentation/index.html.coffee'
  exec 'bin/coffee -bc -o documentation/js documentation/coffee/*.coffee'

  # _.template for CoffeeScript
  template = (text, compile) ->
    escapes =
      "'":  "'"
      '\\': '\\'
      '\r': 'r'
      '\n': 'n'
      '\t': 't'
      '\u2028': 'u2028'
      '\u2029': 'u2029'

    escaper = /\\|'|\r|\n|\t|\u2028|\u2029/g
    matcher = /<%=([\s\S]+?)%>|<%([\s\S]+?)%>|$/g

    # Compile the template source, escaping string literals appropriately.
    index = 0
    source = ""
    text.replace matcher, (match, interpolate, evaluate, offset) ->
      source += text[index...offset].replace escaper, (match) ->
        "\\#{escapes[match]}"
      # strip newline and semi-colon from interpolated expression
      source += "'+\n#{(compile interpolate)[0...-2]}+\n'" if interpolate
      source += "';\n#{compile evaluate}\n__p+='" if evaluate
      index = offset + match.length
      match
    source = "with(obj){\n__p+='#{source}';\n}\n"
    source = "var __p='',__j=Array.prototype.join,
              print=function(){__p+=__j.call(arguments,'');};\n
              #{source}return __p;\n"
    try
      render = new Function 'obj', source
    catch e
      e.source = source
      throw e
    render require: require

  rendered = template fs.readFileSync(source, 'utf-8'), (code) ->
    CoffeeScript.compile code, bare: true
  fs.writeFileSync 'index.html', rendered


task 'doc:source', 'rebuild the internal documentation', ->
  exec 'docco src/*.*coffee && cp -rf docs documentation && rm -r docs', (err) ->
    throw err if err


task 'doc:underscore', 'rebuild the Underscore.coffee documentation page', ->
  exec 'docco examples/underscore.coffee && cp -rf docs documentation && rm -r docs', (err) ->
    throw err if err

task 'bench', 'quick benchmark of compilation time', ->
  {Rewriter} = require './lib/coffee-script/rewriter'
  sources = ['coffee-script', 'grammar', 'helpers', 'lexer', 'nodes', 'rewriter']
  coffee  = sources.map((name) -> fs.readFileSync "src/#{name}.coffee").join '\n'
  litcoffee = fs.readFileSync("src/scope.litcoffee").toString()
  fmt    = (ms) -> " #{bold}#{ "   #{ms}".slice -4 }#{reset} ms"
  total  = 0
  now    = Date.now()
  time   = -> total += ms = -(now - now = Date.now()); fmt ms
  tokens = CoffeeScript.tokens coffee, rewrite: no
  littokens = CoffeeScript.tokens litcoffee, rewrite: no, literate: yes
  tokens = tokens.concat(littokens)
  console.log "Lex    #{time()} (#{tokens.length} tokens)"
  tokens = new Rewriter().rewrite tokens
  console.log "Rewrite#{time()} (#{tokens.length} tokens)"
  nodes  = CoffeeScript.nodes tokens
  console.log "Parse  #{time()}"
  js     = nodes.compile bare: yes
  console.log "Compile#{time()} (#{js.length} chars)"
  console.log "total  #{ fmt total }"


# Run the CoffeeScript test suite.
runTests = (CoffeeScript) ->
  CoffeeScript.register()
  startTime   = Date.now()
  currentFile = null
  passedTests = 0
  failures    = []

  global[name] = func for name, func of require 'assert'

  # Convenience aliases.
  global.CoffeeScript = CoffeeScript
  global.Repl = require './lib/coffee-script/repl'

  # Our test helper function for delimiting different test cases.
  global.test = (description, fn) ->
    try
      fn.test = {description, currentFile}
      fn.call(fn)
      ++passedTests
    catch e
      failures.push
        filename: currentFile
        error: e
        description: description if description?
        source: fn.toString() if fn.toString?

  # See http://wiki.ecmascript.org/doku.php?id=harmony:egal
  egal = (a, b) ->
    if a is b
      a isnt 0 or 1/a is 1/b
    else
      a isnt a and b isnt b

  # A recursive functional equivalence helper; uses egal for testing equivalence.
  arrayEgal = (a, b) ->
    if egal a, b then yes
    else if a instanceof Array and b instanceof Array
      return no unless a.length is b.length
      return no for el, idx in a when not arrayEgal el, b[idx]
      yes

  global.eq      = (a, b, msg) -> ok egal(a, b), msg ? "Expected #{a} to equal #{b}"
  global.arrayEq = (a, b, msg) -> ok arrayEgal(a,b), msg ? "Expected #{a} to deep equal #{b}"

  # When all the tests have run, collect and print errors.
  # If a stacktrace is available, output the compiled function source.
  process.on 'exit', ->
    time = ((Date.now() - startTime) / 1000).toFixed(2)
    message = "passed #{passedTests} tests in #{time} seconds#{reset}"
    return log(message, green) unless failures.length
    log "failed #{failures.length} and #{message}", red
    for fail in failures
      {error, filename, description, source}  = fail
      console.log ''
      log "  #{description}", red if description
      log "  #{error.stack}", red
      console.log "  #{source}" if source
    return

  # Run every test in the `test` folder, recording failures.
  files = fs.readdirSync 'test'
  for file in files when helpers.isCoffee file
    literate = helpers.isLiterate file
    currentFile = filename = path.join 'test', file
    code = fs.readFileSync filename
    try
      CoffeeScript.run code.toString(), {filename, literate}
    catch error
      failures.push {filename, error}
  return !failures.length


task 'test', 'run the CoffeeScript language test suite', ->
  runTests CoffeeScript


task 'test:browser', 'run the test suite against the merged browser script', ->
  source = fs.readFileSync 'extras/coffee-script.js', 'utf-8'
  result = {}
  global.testingBrowser = yes
  (-> eval source).call result
  runTests result.CoffeeScript
