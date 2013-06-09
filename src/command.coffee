# The `coffee` utility. Handles command-line compilation of CoffeeScript
# into various forms: saved into `.js` files or printed to stdout
# or recompiled every time the source is saved,
# printed as a token stream or as the syntax tree, or launch an
# interactive REPL.

# External dependencies.
fs             = require 'fs'
path           = require 'path'
helpers        = require './helpers'
optparse       = require './optparse'
CoffeeScript   = require './coffee-script'
{spawn, exec}  = require 'child_process'
{EventEmitter} = require 'events'

exists         = fs.exists or path.exists
useWinPathSep  = path.sep is '\\'

# Allow CoffeeScript to emit Node.js events.
helpers.extend CoffeeScript, new EventEmitter

printLine = (line) -> process.stdout.write line + '\n'
printWarn = (line) -> process.stderr.write line + '\n'

hidden = (file) -> /^\.|~$/.test file

# The help banner that is printed when `coffee` is called without arguments.
BANNER = '''
  Usage: coffee [options] path/to/script.coffee -- [args]

  If called without options, `coffee` will run your script.
'''

# The list of all the valid option flags that `coffee` knows how to handle.
SWITCHES = [
  ['-b', '--bare',            'compile without a top-level function wrapper']
  ['-c', '--compile',         'compile to JavaScript and save as .js files']
  ['-e', '--eval',            'pass a string from the command line as input']
  ['-h', '--help',            'display this help message']
  ['-i', '--interactive',     'run an interactive CoffeeScript REPL']
  ['-j', '--join [FILE]',     'concatenate the source CoffeeScript before compiling']
  ['-m', '--map',             'generate source map and save as .map files']
  ['-n', '--nodes',           'print out the parse tree that the parser produces']
  [      '--nodejs [ARGS]',   'pass options directly to the "node" binary']
  ['-o', '--output [DIR]',    'set the output directory for compiled JavaScript']
  ['-p', '--print',           'print out the compiled JavaScript']
  ['-s', '--stdio',           'listen for and compile scripts over stdio']
  ['-l', '--literate',        'treat stdio as literate style coffee-script']
  ['-t', '--tokens',          'print out the tokens that the lexer/rewriter produce']
  ['-v', '--version',         'display the version number']
  ['-w', '--watch',           'watch scripts for changes and rerun commands']
]

# Top-level objects shared by all the functions.
opts         = {}
sources      = []
sourceCode   = []
notSources   = {}
watchers     = {}
optionParser = null

# Run `coffee` by parsing passed options and determining what action to take.
# Many flags cause us to divert before compiling anything. Flags passed after
# `--` will be passed verbatim to your script as arguments in `process.argv`
exports.run = ->
  parseOptions()
  return forkNode()                      if opts.nodejs
  return usage()                         if opts.help
  return version()                       if opts.version
  return require('./repl').start()       if opts.interactive
  if opts.watch and not fs.watch
    return printWarn "The --watch feature depends on Node v0.6.0+. You are running #{process.version}."
  return compileStdio()                  if opts.stdio
  return compileScript null, sources[0]  if opts.eval
  return require('./repl').start()       unless sources.length
  literals = if opts.run then sources.splice 1 else []
  process.argv = process.argv[0..1].concat literals
  process.argv[0] = 'coffee'
  for source in sources
    compilePath source, yes, path.normalize source

# Compile a path, which could be a script or a directory. If a directory
# is passed, recursively compile all '.coffee', '.litcoffee', and '.coffee.md'
# extension source files in it and all subdirectories.
compilePath = (source, topLevel, base) ->
  fs.stat source, (err, stats) ->
    throw err if err and err.code isnt 'ENOENT'
    if err?.code is 'ENOENT'
      console.error "File not found: #{source}"
      process.exit 1
    if stats.isDirectory() and path.dirname(source) isnt 'node_modules'
      watchDir source, base if opts.watch
      fs.readdir source, (err, files) ->
        throw err if err and err.code isnt 'ENOENT'
        return if err?.code is 'ENOENT'
        index = sources.indexOf source
        files = files.filter (file) -> not hidden file
        sources[index..index] = (path.join source, file for file in files)
        sourceCode[index..index] = files.map -> null
        files.forEach (file) ->
          compilePath (path.join source, file), no, base
    else if topLevel or helpers.isCoffee source
      watch source, base if opts.watch
      fs.readFile source, (err, code) ->
        throw err if err and err.code isnt 'ENOENT'
        return if err?.code is 'ENOENT'
        compileScript(source, code.toString(), base)
    else
      notSources[source] = yes
      removeSource source, base


# Compile a single source script, containing the given code, according to the
# requested options. If evaluating the script directly sets `__filename`,
# `__dirname` and `module.filename` to be correct relative to the script's path.
compileScript = (file, input, base=null) ->
  o = opts
  options = compileOptions file, base
  try
    t = task = {file, input, options}
    CoffeeScript.emit 'compile', task
    if      o.tokens      then printTokens CoffeeScript.tokens t.input, t.options
    else if o.nodes       then printLine CoffeeScript.nodes(t.input, t.options).toString().trim()
    else if o.run         then CoffeeScript.run t.input, t.options
    else if o.join and t.file isnt o.join
      t.input = helpers.invertLiterate t.input if helpers.isLiterate file
      sourceCode[sources.indexOf(t.file)] = t.input
      compileJoin()
    else
      compiled = CoffeeScript.compile t.input, t.options
      t.output = compiled
      if o.map
        t.output = compiled.js
        t.sourceMap = compiled.v3SourceMap

      CoffeeScript.emit 'success', task
      if o.print
        printLine t.output.trim()
      else if o.compile or o.map
        writeJs base, t.file, t.output, options.jsPath, t.sourceMap
  catch err
    CoffeeScript.emit 'failure', err, task
    return if CoffeeScript.listeners('failure').length
    useColors = process.stdout.isTTY and not process.env.NODE_DISABLE_COLORS
    message = helpers.prettyErrorMessage err, file or '[stdin]', input, useColors
    if o.watch
      printLine message + '\x07'
    else
      printWarn message
      process.exit 1

# Attach the appropriate listeners to compile scripts incoming over **stdin**,
# and write them back to **stdout**.
compileStdio = ->
  code = ''
  stdin = process.openStdin()
  stdin.on 'data', (buffer) ->
    code += buffer.toString() if buffer
  stdin.on 'end', ->
    compileScript null, code

# If all of the source files are done being read, concatenate and compile
# them together.
joinTimeout = null
compileJoin = ->
  return unless opts.join
  unless sourceCode.some((code) -> code is null)
    clearTimeout joinTimeout
    joinTimeout = wait 100, ->
      compileScript opts.join, sourceCode.join('\n'), opts.join

# Watch a source CoffeeScript file using `fs.watch`, recompiling it every
# time the file is updated. May be used in combination with other options,
# such as `--print`.
watch = (source, base) ->

  prevStats = null
  compileTimeout = null

  watchErr = (e) ->
    if e.code is 'ENOENT'
      return if sources.indexOf(source) is -1
      try
        rewatch()
        compile()
      catch e
        removeSource source, base, yes
        compileJoin()
    else throw e

  compile = ->
    clearTimeout compileTimeout
    compileTimeout = wait 25, ->
      fs.stat source, (err, stats) ->
        return watchErr err if err
        return rewatch() if prevStats and stats.size is prevStats.size and
          stats.mtime.getTime() is prevStats.mtime.getTime()
        prevStats = stats
        fs.readFile source, (err, code) ->
          return watchErr err if err
          compileScript(source, code.toString(), base)
          rewatch()

  try
    watcher = fs.watch source, compile
  catch e
    watchErr e

  rewatch = ->
    watcher?.close()
    watcher = fs.watch source, compile


# Watch a directory of files for new additions.
watchDir = (source, base) ->
  readdirTimeout = null
  try
    watcher = fs.watch source, ->
      clearTimeout readdirTimeout
      readdirTimeout = wait 25, ->
        fs.readdir source, (err, files) ->
          if err
            throw err unless err.code is 'ENOENT'
            watcher.close()
            return unwatchDir source, base
          for file in files when not hidden(file) and not notSources[file]
            file = path.join source, file
            continue if sources.some (s) -> s.indexOf(file) >= 0
            sources.push file
            sourceCode.push null
            compilePath file, no, base
  catch e
    throw e unless e.code is 'ENOENT'

unwatchDir = (source, base) ->
  prevSources = sources[..]
  toRemove = (file for file in sources when file.indexOf(source) >= 0)
  removeSource file, base, yes for file in toRemove
  return unless sources.some (s, i) -> prevSources[i] isnt s
  compileJoin()

# Remove a file from our source list, and source code cache. Optionally remove
# the compiled JS version as well.
removeSource = (source, base, removeJs) ->
  index = sources.indexOf source
  sources.splice index, 1
  sourceCode.splice index, 1
  if removeJs and not opts.join
    jsPath = outputPath source, base
    exists jsPath, (itExists) ->
      if itExists
        fs.unlink jsPath, (err) ->
          throw err if err and err.code isnt 'ENOENT'
          timeLog "removed #{source}"

# Get the corresponding output JavaScript path for a source file.
outputPath = (source, base, extension=".js") ->
  basename  = helpers.baseFileName source, yes, useWinPathSep
  srcDir    = path.dirname source
  baseDir   = if base in ['.', './'] then srcDir else srcDir.substring base.length
  dir       = if opts.output then path.join opts.output, baseDir else srcDir
  path.join dir, basename + extension

# Write out a JavaScript source file with the compiled code. By default, files
# are written out in `cwd` as `.js` files with the same name, but the output
# directory can be customized with `--output`.
#
# If `generatedSourceMap` is provided, this will write a `.map` file into the
# same directory as the `.js` file.
writeJs = (base, sourcePath, js, jsPath, generatedSourceMap = null) ->
  sourceMapPath = outputPath sourcePath, base, ".map"
  jsDir  = path.dirname jsPath
  compile = ->
    if opts.compile
      js = ' ' if js.length <= 0
      if generatedSourceMap then js = "#{js}\n/*\n//@ sourceMappingURL=#{helpers.baseFileName sourceMapPath, no, useWinPathSep}\n*/\n"
      fs.writeFile jsPath, js, (err) ->
        if err
          printLine err.message
        else if opts.compile and opts.watch
          timeLog "compiled #{sourcePath}"
    if generatedSourceMap
      fs.writeFile sourceMapPath, generatedSourceMap, (err) ->
        if err
          printLine "Could not write source map: #{err.message}"
  exists jsDir, (itExists) ->
    if itExists then compile() else exec "mkdir -p #{jsDir}", compile

# Convenience for cleaner setTimeouts.
wait = (milliseconds, func) -> setTimeout func, milliseconds

# When watching scripts, it's useful to log changes with the timestamp.
timeLog = (message) ->
  console.log "#{(new Date).toLocaleTimeString()} - #{message}"

# Pretty-print a stream of tokens, sans location data.
printTokens = (tokens) ->
  strings = for token in tokens
    tag = token[0]
    value = token[1].toString().replace(/\n/, '\\n')
    "[#{tag} #{value}]"
  printLine strings.join(' ')

# Use the [OptionParser module](optparse.html) to extract all options from
# `process.argv` that are specified in `SWITCHES`.
parseOptions = ->
  optionParser  = new optparse.OptionParser SWITCHES, BANNER
  o = opts      = optionParser.parse process.argv[2..]
  o.compile     or=  !!o.output
  o.run         = not (o.compile or o.print or o.map)
  o.print       = !!  (o.print or (o.eval or o.stdio and o.compile))
  sources       = o.arguments
  sourceCode[i] = null for source, i in sources
  return

# The compile-time options to pass to the CoffeeScript compiler.
compileOptions = (filename, base) ->
  answer = {
    filename
    literate: opts.literate or helpers.isLiterate(filename)
    bare: opts.bare
    header: opts.compile
    sourceMap: opts.map
  }
  if filename
    if base
      cwd = process.cwd()
      jsPath = outputPath filename, base
      jsDir = path.dirname jsPath
      answer = helpers.merge answer, {
        jsPath
        sourceRoot: path.relative jsDir, cwd
        sourceFiles: [path.relative cwd, filename]
        generatedFile: helpers.baseFileName(jsPath, no, useWinPathSep)
      }
    else
      answer = helpers.merge answer,
        sourceRoot: ""
        sourceFiles: [helpers.baseFileName filename, no, useWinPathSep]
        generatedFile: helpers.baseFileName(filename, yes, useWinPathSep) + ".js"
  answer

# Start up a new Node.js instance with the arguments in `--nodejs` passed to
# the `node` binary, preserving the other options.
forkNode = ->
  nodeArgs = opts.nodejs.split /\s+/
  args     = process.argv[1..]
  args.splice args.indexOf('--nodejs'), 2
  spawn process.execPath, nodeArgs.concat(args),
    cwd:        process.cwd()
    env:        process.env
    customFds:  [0, 1, 2]

# Print the `--help` usage message and exit. Deprecated switches are not
# shown.
usage = ->
  printLine (new optparse.OptionParser SWITCHES, BANNER).help()

# Print the `--version` message and exit.
version = ->
  printLine "CoffeeScript version #{CoffeeScript.VERSION}"
