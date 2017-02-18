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

# Used in folder names like `docs/v1`.
majorVersion = parseInt CoffeeScript.VERSION.split('.')[0], 10


# Log a message with a color.
log = (message, color, explanation) ->
  console.log color + message + reset + ' ' + (explanation or '')


spawnNodeProcess = (args, output = 'stderr', callback) ->
  relayOutput = (buffer) -> console.log buffer.toString()
  proc =         spawn 'node', args
  proc.stdout.on 'data', relayOutput if output is 'both' or output is 'stdout'
  proc.stderr.on 'data', relayOutput if output is 'both' or output is 'stderr'
  proc.on        'exit', (status) -> callback(status) if typeof callback is 'function'

# Run a CoffeeScript through our node/coffee interpreter.
run = (args, callback) ->
  spawnNodeProcess ['bin/coffee'].concat(args), 'stderr', (status) ->
    process.exit(1) if status isnt 0
    callback() if typeof callback is 'function'


# Build the CoffeeScript language from source.
buildParser = ->
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

buildExceptParser = (callback) ->
  files = fs.readdirSync 'src'
  files = ('src/' + file for file in files when file.match(/\.(lit)?coffee$/))
  run ['-c', '-o', 'lib/coffee-script'].concat(files), callback

build = (callback) ->
  buildParser()
  buildExceptParser callback

testBuiltCode = (watch = no) ->
  csPath = './lib/coffee-script'
  csDir  = path.dirname require.resolve csPath

  for mod of require.cache when csDir is mod[0 ... csDir.length]
    delete require.cache[mod]

  testResults = runTests require csPath
  unless watch
    process.exit 1 unless testResults

buildAndTest = (includingParser = yes, harmony = no) ->
  process.stdout.write '\x1Bc' # Clear terminal screen.
  execSync 'git checkout lib/*', stdio: [0,1,2] # Reset the generated compiler.

  buildArgs = ['bin/cake']
  buildArgs.push if includingParser then 'build' else 'build:except-parser'
  log "building#{if includingParser then ', including parser' else ''}...", green
  spawnNodeProcess buildArgs, 'both', ->
    log 'testing...', green
    testArgs = if harmony then ['--harmony'] else []
    testArgs = testArgs.concat ['bin/cake', 'test']
    spawnNodeProcess testArgs, 'both'

watchAndBuildAndTest = (harmony = no) ->
  buildAndTest yes, harmony
  fs.watch 'src/', interval: 200, (eventType, filename) ->
    if eventType is 'change'
      log "src/#{filename} changed, rebuilding..."
      buildAndTest (filename is 'grammar.coffee'), harmony
  fs.watch 'test/', {interval: 200, recursive: yes}, (eventType, filename) ->
    if eventType is 'change'
      log "test/#{filename} changed, rebuilding..."
      buildAndTest no, harmony


task 'build', 'build the CoffeeScript compiler from source', build

task 'build:parser', 'build the Jison parser only', buildParser

task 'build:except-parser', 'build the CoffeeScript compiler, except for the Jison parser', buildExceptParser

task 'build:full', 'build the CoffeeScript compiler from source twice, and run the tests', ->
  build ->
    build testBuiltCode

task 'build:browser', 'build the merged script for inclusion in the browser', ->
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

task 'build:watch', 'watch and continually rebuild the CoffeeScript compiler, running tests on each build', ->
  watchAndBuildAndTest()

task 'build:watch:harmony', 'watch and continually rebuild the CoffeeScript compiler, running harmony tests on each build', ->
  watchAndBuildAndTest yes


buildDocs = (watch = no) ->
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

  if watch
    for target in [indexFile, versionedSourceFolder, examplesSourceFolder, sectionsSourceFolder]
      fs.watch target, interval: 200, renderIndex
    log 'watching...', green

task 'doc:site', 'build the documentation for the website', ->
  buildDocs()

task 'doc:site:watch', 'watch and continually rebuild the documentation for the website', ->
  buildDocs yes


buildDocTests = (watch = no) ->
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

  if watch
    for target in [testFile, testsSourceFolder]
      fs.watch target, interval: 200, renderTest
    log 'watching...', green

task 'doc:test', 'build the browser-based tests', ->
  buildDocTests()

task 'doc:test:watch', 'watch and continually rebuild the browser-based tests', ->
  buildDocTests yes


buildAnnotatedSource = (watch = no) ->
  do generateAnnotatedSource = ->
    exec "node_modules/docco/bin/docco src/*.*coffee --output docs/v#{majorVersion}/annotated-source", (err) -> throw err if err
    log 'generated', green, "annotated source in docs/v#{majorVersion}/annotated-source/"

  if watch
    fs.watch 'src/', interval: 200, generateAnnotatedSource
    log 'watching...', green

task 'doc:source', 'build the annotated source documentation', ->
  buildAnnotatedSource()

task 'doc:source:watch', 'watch and continually rebuild the annotated source documentation', ->
  buildAnnotatedSource yes


task 'release', 'build and test the CoffeeScript source, and build the documentation', ->
  invoke 'build:full'
  invoke 'build:browser'
  invoke 'doc:site'
  invoke 'doc:test'
  invoke 'doc:source'

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
