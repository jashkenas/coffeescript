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
  extend global, require('utils')
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


runTests = (CoffeeScript) ->
  startTime = Date.now()
  passedTests = 0
  failures = []

  for name, func of require 'assert'
    global[name] = ->
      passedTests += 1
      func arguments...

  global.eq = global.strictEqual
  global.CoffeeScript = CoffeeScript
  global.test = (description, fn) ->
    try fn()
    catch e
      e.message = description if description?
      e.source = fn.toString() if fn.toString?
      throw e

  process.on 'exit', ->
    time = ((Date.now() - startTime) / 1000).toFixed(2)
    message = "passed #{passedTests} tests in #{time} seconds#{reset}"
    if failures.length is 0
      log message, green
    else
      log "failed #{failures.length} and #{message}", red
      for fail in failures
        match = fail.error.stack.match(new RegExp(fail.file+":(\\d+):(\\d+)"))
        [match,line,column] = match if match
        line ?= "unknown"
        column ?= "unknown"
        log "  #{fail.file.replace(/\.coffee$/,'.js')}: line #{line}, column #{column}", red
        console.log "  #{fail.error.message}" if fail.error.message?
        # output a cleaned-up version of the function source
        if fail.error.source?
          source = fail.error.source
          splitSource = source.split("\n")
          # count the number of spaces on the last line to determine indentation level
          [lastLineSpaces] = splitSource[splitSource.length-1].match(/\ */)
          if splitSource.length > 1 and lastLineSpaces
            paddedSource = []
            splitSource[0] = lastLineSpaces + splitSource[0]
            for line in splitSource
              # this should read a single value for indentation size (currently 4)
              newLine = if lastLineSpaces.length > 4
                line[(lastLineSpaces.length-4)..]
              else
                "    "[lastLineSpaces.length..] + line
              paddedSource.push newLine
            source = paddedSource.join("\n")
          console.log source

  fs.readdir 'test', (err, files) ->
    files.forEach (file) ->
      return unless file.match(/\.coffee$/i)
      fileName = path.join 'test', file
      fs.readFile fileName, (err, code) ->
        try
          CoffeeScript.run code.toString(), {fileName}
        catch err
          failures.push {file: fileName, error: err}


task 'test', 'run the CoffeeScript language test suite', ->
  runTests CoffeeScript


task 'test:browser', 'run the test suite against the merged browser script', ->
  source = fs.readFileSync 'extras/coffee-script.js', 'utf-8'
  result = {}
  (-> eval source).call result
  runTests result.CoffeeScript
