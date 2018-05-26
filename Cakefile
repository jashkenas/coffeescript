fs                        = require 'fs'
os                        = require 'os'
path                      = require 'path'
_                         = require 'underscore'
{ spawn, exec, execSync } = require 'child_process'
CoffeeScript              = require './lib/coffeescript'
helpers                   = require './lib/coffeescript/helpers'

# ANSI Terminal Colors.
bold = red = green = yellow = reset = ''
unless process.env.NODE_DISABLE_COLORS
  bold   = '\x1B[0;1m'
  red    = '\x1B[0;31m'
  green  = '\x1B[0;32m'
  yellow = '\x1B[0;33m'
  reset  = '\x1B[0m'

# Built file header.
header = """
  /**
   * CoffeeScript Compiler v#{CoffeeScript.VERSION}
   * https://coffeescript.org
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
  # We don't need `moduleMain`, since the parser is unlikely to be run standalone.
  parser = require('./lib/coffeescript/grammar').parser.generate(moduleMain: ->)
  fs.writeFileSync 'lib/coffeescript/parser.js', parser

buildExceptParser = (callback) ->
  files = fs.readdirSync 'src'
  files = ('src/' + file for file in files when file.match(/\.(lit)?coffee$/))
  run ['-c', '-o', 'lib/coffeescript'].concat(files), callback

build = (callback) ->
  buildParser()
  buildExceptParser callback

transpile = (code) ->
  babel = require 'babel-core'
  presets = []
  # Exclude the `modules` plugin in order to not break the `}(this));`
  # at the end of the `build:browser` code block.
  presets.push ['env', {modules: no}] unless process.env.TRANSFORM is 'false'
  presets.push ['minify', {mangle: no}] unless process.env.MINIFY is 'false'
  babelOptions =
    compact: process.env.MINIFY isnt 'false'
    presets: presets
    sourceType: 'script'
  { code } = babel.transform code, babelOptions unless presets.length is 0
  code

testBuiltCode = (watch = no) ->
  csPath = './lib/coffeescript'
  csDir  = path.dirname require.resolve csPath

  for mod of require.cache when csDir is mod[0 ... csDir.length]
    delete require.cache[mod]

  testResults = runTests require csPath
  unless watch
    process.exit 1 unless testResults

buildAndTest = (includingParser = yes, harmony = no) ->
  process.stdout.write '\x1Bc' # Clear terminal screen.
  execSync 'git checkout lib/*', stdio: 'inherit' # Reset the generated compiler.

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

task 'build:browser', 'merge the built scripts into a single file for use in a browser', ->
  code = """
  require['../../package.json'] = (function() {
    return #{fs.readFileSync "./package.json"};
  })();
  """
  for name in ['helpers', 'rewriter', 'lexer', 'parser', 'scope', 'nodes', 'sourcemap', 'coffeescript', 'browser']
    code += """
      require['./#{name}'] = (function() {
        var exports = {}, module = {exports: exports};
        #{fs.readFileSync "lib/coffeescript/#{name}.js"}
        return module.exports;
      })();
    """
  code = """
    (function(root) {
      var CoffeeScript = function() {
        function require(path){ return require[path]; }
        #{code}
        return require['./browser'];
      }();

      if (typeof define === 'function' && define.amd) {
        define(function() { return CoffeeScript; });
      } else {
        root.CoffeeScript = CoffeeScript;
      }
    }(this));
  """
  code = transpile code
  outputFolder = "docs/v#{majorVersion}/browser-compiler"
  fs.mkdirSync outputFolder unless fs.existsSync outputFolder
  fs.writeFileSync "#{outputFolder}/coffeescript.js", header + '\n' + code

task 'build:browser:full', 'merge the built scripts into a single file for use in a browser, and test it', ->
  invoke 'build:browser'
  console.log "built ... running browser tests:"
  invoke 'test:browser'

task 'build:watch', 'watch and continually rebuild the CoffeeScript compiler, running tests on each build', ->
  watchAndBuildAndTest()

task 'build:watch:harmony', 'watch and continually rebuild the CoffeeScript compiler, running harmony tests on each build', ->
  watchAndBuildAndTest yes


buildDocs = (watch = no) ->
  # Constants
  indexFile            = 'documentation/site/index.html'
  siteSourceFolder     = "documentation/site"
  sectionsSourceFolder = 'documentation/sections'
  examplesSourceFolder = 'documentation/examples'
  outputFolder         = "docs/v#{majorVersion}"

  # Helpers
  releaseHeader = (date, version, prevVersion) ->
    """
      <h3>#{prevVersion and "<a href=\"https://github.com/jashkenas/coffeescript/compare/#{prevVersion}...#{version}\">#{version}</a>" or version}
        <span class="timestamp"> &mdash; <time datetime="#{date}">#{date}</time></span>
      </h3>
    """

  codeFor = require "./documentation/site/code.coffee"

  htmlFor = ->
    hljs = require 'highlight.js'
    hljs.configure classPrefix: ''
    markdownRenderer = require('markdown-it')
      html: yes
      typographer: yes
      highlight: (str, lang) ->
        # From https://github.com/markdown-it/markdown-it#syntax-highlighting
        if lang and hljs.getLanguage(lang)
          try
            return hljs.highlight(lang, str).value
          catch ex
        return '' # No syntax highlighting


    # Add some custom overrides to Markdown-It’s rendering, per
    # https://github.com/markdown-it/markdown-it/blob/master/docs/architecture.md#renderer
    defaultFence = markdownRenderer.renderer.rules.fence
    markdownRenderer.renderer.rules.fence = (tokens, idx, options, env, slf) ->
      code = tokens[idx].content
      if code.indexOf('codeFor(') is 0 or code.indexOf('releaseHeader(') is 0
        "<%= #{code} %>"
      else
        "<blockquote class=\"uneditable-code-block\">#{defaultFence.apply @, arguments}</blockquote>"

    (file, bookmark) ->
      md = fs.readFileSync "#{sectionsSourceFolder}/#{file.replace /\//g, path.sep}.md", 'utf-8'
      md = md.replace /<%= releaseHeader %>/g, releaseHeader
      md = md.replace /<%= majorVersion %>/g, majorVersion
      md = md.replace /<%= fullVersion %>/g, CoffeeScript.VERSION
      html = markdownRenderer.render md
      html = _.template(html)
        codeFor: codeFor()
        releaseHeader: releaseHeader

  includeScript = ->
    (file) ->
      file = "#{siteSourceFolder}/#{file}" unless '/' in file
      code = fs.readFileSync file, 'utf-8'
      code = CoffeeScript.compile code
      code = transpile code
      code

  include = ->
    (file) ->
      file = "#{siteSourceFolder}/#{file}" unless '/' in file
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
          includeScript: includeScript()
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
    for target in [indexFile, siteSourceFolder, examplesSourceFolder, sectionsSourceFolder]
      fs.watch target, interval: 200, renderIndex
    log 'watching...', green

task 'doc:site', 'build the documentation for the website', ->
  buildDocs()

task 'doc:site:watch', 'watch and continually rebuild the documentation for the website', ->
  buildDocs yes


buildDocTests = (watch = no) ->
  # Constants
  testFile          = 'documentation/site/test.html'
  testsSourceFolder = 'test'
  outputFolder      = "docs/v#{majorVersion}"

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
    exec "cd src && ../node_modules/docco/bin/docco *.*coffee --output ../docs/v#{majorVersion}/annotated-source", (err) -> throw err if err
    log 'generated', green, "annotated source in docs/v#{majorVersion}/annotated-source/"

  if watch
    fs.watch 'src/', interval: 200, generateAnnotatedSource
    log 'watching...', green

task 'doc:source', 'build the annotated source documentation', ->
  buildAnnotatedSource()

task 'doc:source:watch', 'watch and continually rebuild the annotated source documentation', ->
  buildAnnotatedSource yes


task 'release', 'build and test the CoffeeScript source, and build the documentation', ->
  execSync '''
    cake build:full
    cake build:browser
    cake test:browser
    cake test:integrations
    cake doc:site
    cake doc:test
    cake doc:source''', stdio: 'inherit'


task 'bench', 'quick benchmark of compilation time', ->
  {Rewriter} = require './lib/coffeescript/rewriter'
  sources = ['coffeescript', 'grammar', 'helpers', 'lexer', 'nodes', 'rewriter']
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
  CoffeeScript.register() unless global.testingBrowser

  # These are attached to `global` so that they’re accessible from within
  # `test/async.coffee`, which has an async-capable version of
  # `global.test`.
  global.currentFile = null
  global.passedTests = 0
  global.failures    = []

  global[name] = func for name, func of require 'assert'

  # Convenience aliases.
  global.CoffeeScript = CoffeeScript
  global.Repl   = require './lib/coffeescript/repl'
  global.bold   = bold
  global.red    = red
  global.green  = green
  global.yellow = yellow
  global.reset  = reset

  asyncTests = []
  onFail = (description, fn, err) ->
    failures.push
      filename: global.currentFile
      error: err
      description: description
      source: fn.toString() if fn.toString?

  # Our test helper function for delimiting different test cases.
  global.test = (description, fn) ->
    try
      fn.test = {description, currentFile}
      result = fn.call(fn)
      if result instanceof Promise # An async test.
        asyncTests.push result
        result.then ->
          passedTests++
        .catch (err) ->
          onFail description, fn, err
      else
        passedTests++
    catch err
      onFail description, fn, err

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

  # Run every test in the `test` folder, recording failures, except for files
  # we’re skipping because the features to be tested are unsupported in the
  # current Node runtime.
  testFilesToSkip = []
  skipUnless = (featureDetect, filenames) ->
    unless (try new Function featureDetect)
      testFilesToSkip = testFilesToSkip.concat filenames
  skipUnless 'async () => {}', ['async.coffee', 'async_iterators.coffee']
  skipUnless 'async function* generator() { yield 42; }', ['async_iterators.coffee']
  skipUnless 'var a = 2 ** 2; a **= 3', ['exponentiation.coffee']
  skipUnless 'var {...a} = {}', ['object_rest_spread.coffee']
  skipUnless '/foo.bar/s.test("foo\tbar")', ['regex_dotall.coffee']
  files = fs.readdirSync('test').filter (filename) ->
    filename not in testFilesToSkip

  startTime = Date.now()
  for file in files when helpers.isCoffee file
    literate = helpers.isLiterate file
    currentFile = filename = path.join 'test', file
    code = fs.readFileSync filename
    try
      CoffeeScript.run code.toString(), {filename, literate}
    catch error
      failures.push {filename, error}

  Promise.all(asyncTests).then ->
    Promise.reject() if failures.length isnt 0


task 'test', 'run the CoffeeScript language test suite', ->
  runTests(CoffeeScript).catch -> process.exit 1


task 'test:browser', 'run the test suite against the merged browser script', ->
  source = fs.readFileSync "docs/v#{majorVersion}/browser-compiler/coffeescript.js", 'utf-8'
  result = {}
  global.testingBrowser = yes
  (-> eval source).call result
  runTests(CoffeeScript).catch -> process.exit 1


task 'test:integrations', 'test the module integrated with other libraries and environments', ->
  # Tools like Webpack and Browserify generate builds intended for a browser
  # environment where Node modules are not available. We want to ensure that
  # the CoffeeScript module as presented by the `browser` key in `package.json`
  # can be built by such tools; if such a build succeeds, it verifies that no
  # Node modules are required as part of the compiler (as opposed to the tests)
  # and that therefore the compiler will run in a browser environment.
  tmpdir = os.tmpdir()
  webpack = require 'webpack'
  webpack {
    entry: './'
    output:
      path: tmpdir
      filename: 'coffeescript.js'
      library: 'CoffeeScript'
      libraryTarget: 'commonjs2'
  }, (err, stats) ->
    if err or stats.hasErrors()
      if err
        console.error err.stack or err
        console.error err.details if err.details
      if stats.hasErrors()
        console.error error for error in stats.compilation.errors
      if stats.hasWarnings()
        console.warn warning for warning in stats.compilation.warnings
      process.exit 1

    builtCompiler = path.join tmpdir, 'coffeescript.js'
    CoffeeScript = require builtCompiler
    global.testingBrowser = yes
    testResults = runTests CoffeeScript
    fs.unlinkSync builtCompiler
    process.exit 1 unless testResults
