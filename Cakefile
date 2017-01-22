fs                        = require 'fs'
path                      = require 'path'
_                         = require 'underscore'
{ spawn, exec, execSync } = require 'child_process'
CoffeeScript              = require './lib/coffee-script'
helpers                   = require './lib/coffee-script/helpers'

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

# Used in folder names like docs/v1
majorVersion = parseInt CoffeeScript.VERSION.split('.')[0], 10

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
    process.exit(1) if status isnt 0
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
  console.log "Installing CoffeeScript to #{lib}"
  console.log "Linking to #{node}"
  console.log "Linking 'coffee' to #{bin}/coffee"
  exec([
    "mkdir -p #{lib} #{bin}"
    "cp -rf bin lib LICENSE README.md package.json src #{lib}"
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
  helpers.extend global, require 'util'
  require 'jison'
  parser = require('./lib/coffee-script/grammar').parser.generate()
  # Patch Jison’s output, until https://github.com/zaach/jison/pull/339 is accepted,
  # to ensure that require('fs') is only called where it exists.
  parser = parser.replace "var source = require('fs')", """
      var source = '';
          var fs = require('fs');
          if (typeof fs !== 'undefined' && fs !== null)
              source = fs"""
  fs.writeFileSync 'lib/coffee-script/parser.js', parser


task 'build:browser', 'rebuild the merged script for inclusion in the browser', ->
  code = """
  require['../../package.json'] = (function() {
    return #{fs.readFileSync "./package.json"};
  })();
  """
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
    {compiledCode: code} = require('google-closure-compiler-js').compile
      jsCode: [
        src: code
        languageOut: if majorVersion is 1 then 'ES5' else 'ES6'
      ]
  outputFolder = "docs/v#{majorVersion}/browser-compiler"
  fs.mkdirSync outputFolder unless fs.existsSync outputFolder
  fs.writeFileSync "#{outputFolder}/coffee-script.js", header + '\n' + code
  console.log "built ... running browser tests:"
  invoke 'test:browser'


task 'doc:site', 'watch and continually rebuild the documentation for the website', ->
  # Constants
  indexFile = 'documentation/index.html'
  versionedSourceFolder = "documentation/v#{majorVersion}"
  sectionsSourceFolder = 'documentation/sections'
  examplesSourceFolder = 'documentation/examples'
  outputFolder = "docs/v#{majorVersion}"

  # Helpers
  releaseHeader = (date, version, prevVersion) ->
    monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']

    formatDate = (date) ->
      date.replace /^(\d\d\d\d)-(\d\d)-(\d\d)$/, (match, $1, $2, $3) ->
        "#{monthNames[$2 - 1]} #{+$3}, #{$1}"

    """
      <div class="anchor" id="#{version}"></div>
      <h2 class="header">
        #{prevVersion and "<a href=\"https://github.com/jashkenas/coffeescript/compare/#{prevVersion}...#{version}\">#{version}</a>" or version}
        <span class="timestamp"> &mdash; <time datetime="#{date}">#{formatDate date}</time></span>
      </h2>
    """

  codeFor = require "./documentation/v#{majorVersion}/code.coffee"

  htmlFor = ->
    marked = require 'marked'
    markdownRenderer = new marked.Renderer()
    markdownRenderer.heading = (text, level) ->
      "<h#{level}>#{text}</h#{level}>" # Don’t let marked add an id
    markdownRenderer.code = (code) ->
      if code.indexOf('codeFor(') is 0 or code.indexOf('releaseHeader(') is 0
        "<%= #{code} %>"
      else
        "<pre><code>#{code}</code></pre>" # Default

    (file, bookmark) ->
      md = fs.readFileSync "#{sectionsSourceFolder}/#{file}.md", 'utf-8'
      md = md.replace /<%= releaseHeader %>/g, releaseHeader
      md = md.replace /<%= majorVersion %>/g, majorVersion
      md = md.replace /<%= fullVersion %>/g, CoffeeScript.VERSION
      html = marked md, renderer: markdownRenderer
      html = _.template(html)
        codeFor: codeFor()
        releaseHeader: releaseHeader

  include = ->
    (file) ->
      file = "#{versionedSourceFolder}/#{file}" if file.indexOf('/') is -1
      output = fs.readFileSync file, 'utf-8'
      if /\.html$/.test(file)
        render = _.template output
        output = render
          releaseHeader: releaseHeader
          majorVersion: majorVersion
          fullVersion: CoffeeScript.VERSION
          htmlFor: htmlFor()
          codeFor: codeFor()
          include: include()
      output

  # Task
  do renderIndex = ->
    render = _.template fs.readFileSync(indexFile, 'utf-8')
    output = render
      include: include()
    fs.writeFileSync "#{outputFolder}/index.html", output
    log 'compiled', green, "#{indexFile} → #{outputFolder}/index.html"
  try
    fs.symlinkSync "v#{majorVersion}/index.html", 'docs/index.html'
  catch exception

  for target in [indexFile, versionedSourceFolder, examplesSourceFolder, sectionsSourceFolder]
    fs.watch target, interval: 200, renderIndex
  log 'watching...' , green


task 'doc:test', 'watch and continually rebuild the browser-based tests', ->
  # Constants
  testFile = 'documentation/test.html'
  testsSourceFolder = 'test'
  outputFolder = "docs/v#{majorVersion}"

  # Included in test.html
  testHelpers = fs.readFileSync('test/support/helpers.coffee', 'utf-8').replace /exports\./g, '@'

  # Helpers
  testsInScriptBlocks = ->
    output = ''
    for filename in fs.readdirSync testsSourceFolder
      if filename.indexOf('.coffee') isnt -1
        type = 'coffeescript'
      else if filename.indexOf('.litcoffee') isnt -1
        type = 'literate-coffeescript'
      else
        continue

      # Set the type to text/x-coffeescript or text/x-literate-coffeescript
      # to prevent the browser compiler from automatically running the script
      output += """
        <script type="text/x-#{type}" class="test" id="#{filename.split('.')[0]}">
        #{fs.readFileSync "test/#{filename}", 'utf-8'}
        </script>\n
      """
    output

  # Task
  do renderTest = ->
    render = _.template fs.readFileSync(testFile, 'utf-8')
    output = render
      testHelpers: testHelpers
      tests: testsInScriptBlocks()
    fs.writeFileSync "#{outputFolder}/test.html", output
    log 'compiled', green, "#{testFile} → #{outputFolder}/test.html"

  for target in [testFile, testsSourceFolder]
    fs.watch target, interval: 200, renderTest
  log 'watching...' , green


task 'doc:source', 'rebuild the annotated source documentation', ->
  exec "node_modules/docco/bin/docco src/*.*coffee --output docs/v#{majorVersion}/annotated-source", (err) -> throw err if err


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

  helpers.extend global, require './test/support/helpers'

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
  source = fs.readFileSync "docs/v#{majorVersion}/browser-compiler/coffee-script.js", 'utf-8'
  result = {}
  global.testingBrowser = yes
  (-> eval source).call result
  runTests result.CoffeeScript
