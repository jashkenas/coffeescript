# The `coffee` utility. Handles command-line compilation of CoffeeScript
# into various forms: saved into `.js` files or printed to stdout, piped to
# [JavaScript Lint](http://javascriptlint.com/) or recompiled every time the source is
# saved, printed as a token stream or as the syntax tree, or launch an
# interactive REPL.

# External dependencies.
fs             = require 'fs'
path           = require 'path'
helpers        = require './helpers'
optparse       = require './optparse'
CoffeeScript   = require './coffee-script'
{spawn, exec}  = require 'child_process'
{EventEmitter} = require 'events'

# Allow CoffeeScript to emit Node.js events.
helpers.extend CoffeeScript, new EventEmitter

printLine = (line) -> process.stdout.write line + '\n'
printWarn = (line) -> process.stderr.write line + '\n'

# The help banner that is printed when `coffee` is called without arguments.
BANNER = '''
  Usage: coffee [options] path/to/script.coffee

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
  ['-l', '--lint',            'pipe the compiled JavaScript through JavaScript Lint']
  ['-n', '--nodes',           'print out the parse tree that the parser produces']
  [      '--nodejs [ARGS]',   'pass options directly to the "node" binary']
  ['-o', '--output [DIR]',    'set the output directory for compiled JavaScript']
  ['-p', '--print',           'print out the compiled JavaScript']
  ['-r', '--require [FILE*]', 'require a library before executing your script']
  ['-s', '--stdio',           'listen for and compile scripts over stdio']
  ['-t', '--tokens',          'print out the tokens that the lexer/rewriter produce']
  ['-v', '--version',         'display the version number']
  ['-w', '--watch',           'watch scripts for changes and rerun commands']
]

# Top-level objects shared by all the functions.
opts         = {}
sources      = []
contents     = []
optionParser = null

# Run `coffee` by parsing passed options and determining what action to take.
# Many flags cause us to divert before compiling anything. Flags passed after
# `--` will be passed verbatim to your script as arguments in `process.argv`
exports.run = ->
  parseOptions()
  return forkNode()                      if opts.nodejs
  return usage()                         if opts.help
  return version()                       if opts.version
  loadRequires()                         if opts.require
  return require './repl'                if opts.interactive
  return compileStdio()                  if opts.stdio
  return compileScript null, sources[0]  if opts.eval
  return require './repl'                unless sources.length
  if opts.run
    opts.literals = sources.splice(1).concat opts.literals
  process.argv = process.argv.slice(0, 2).concat opts.literals
  process.argv[0] = 'coffee'
  process.execPath = require.main.filename
  compileScripts()

# Asynchronously read in each CoffeeScript in a list of source files and
# compile them. If a directory is passed, recursively compile all
# '.coffee' extension source files in it and all subdirectories.
compileScripts = ->
  unprocessed = []
  remaining_files = ->
    total = 0
    total += x for x in unprocessed
    total
  trackUnprocessedFiles = (sourceIndex, fileCount) ->
    unprocessed[sourceIndex] ?= 0
    unprocessed[sourceIndex] += fileCount
  trackCompleteFiles = (sourceIndex, fileCount) ->
    unprocessed[sourceIndex] -= fileCount
    if opts.join
      if helpers.compact(contents).length > 0 and remaining_files() == 0
        compileJoin()
  for source in sources
    trackUnprocessedFiles sources.indexOf(source), 1
  for source in sources
    base = path.join(source)
    compile = (source, sourceIndex, topLevel) ->
      path.exists source, (exists) ->
        if topLevel and not exists and source[-7..] isnt '.coffee'
          return compile "#{source}.coffee", sourceIndex, topLevel
        throw new Error "File not found: #{source}" if topLevel and not exists
        fs.stat source, (err, stats) ->
          throw err if err
          if stats.isDirectory()
            fs.readdir source, (err, files) ->
              throw err if err
              trackUnprocessedFiles sourceIndex, files.length
              for file in files
                compile path.join(source, file), sourceIndex
              trackCompleteFiles sourceIndex, 1
          else if topLevel or path.extname(source) is '.coffee'
            fs.readFile source, (err, code) ->
              throw err if err
              if opts.join
                contents[sourceIndex] = helpers.compact([contents[sourceIndex], code.toString()]).join('\n')
              else
                compileScript(source, code.toString(), base)
              trackCompleteFiles sourceIndex, 1
            watch source, base if opts.watch and not opts.join
          else
            trackCompleteFiles sourceIndex, 1
    compile source, sources.indexOf(source), true

# Compile a single source script, containing the given code, according to the
# requested options. If evaluating the script directly sets `__filename`,
# `__dirname` and `module.filename` to be correct relative to the script's path.
compileScript = (file, input, base) ->
  o = opts
  options = compileOptions file
  try
    t = task = {file, input, options}
    CoffeeScript.emit 'compile', task
    if      o.tokens      then printTokens CoffeeScript.tokens t.input
    else if o.nodes       then printLine CoffeeScript.nodes(t.input).toString().trim()
    else if o.run         then CoffeeScript.run t.input, t.options
    else
      t.output = CoffeeScript.compile t.input, t.options
      CoffeeScript.emit 'success', task
      if o.print          then printLine t.output.trim()
      else if o.compile   then writeJs t.file, t.output, base
      else if o.lint      then lint t.file, t.output
  catch err
    CoffeeScript.emit 'failure', err, task
    return if CoffeeScript.listeners('failure').length
    return printLine err.message if o.watch
    printWarn err instanceof Error and err.stack or "ERROR: #{err}"
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

# After all of the source files are done being read, concatenate and compile
# them together.
compileJoin = ->
  code = contents.join '\n'
  compileScript opts.join, code, opts.join

# Load files that are to-be-required before compilation occurs.
loadRequires = ->
  realFilename = module.filename
  module.filename = '.'
  require req for req in opts.require
  module.filename = realFilename

# Watch a source CoffeeScript file using `fs.watch`, recompiling it every
# time the file is updated. May be used in combination with other options,
# such as `--lint` or `--print`.
watch = (source, base) ->
  fs.stat source, (err, prevStats)->
    throw err if err
    fs.watch source, (event) ->
      if event is 'change'
        fs.stat source, (err, stats) ->
          throw err if err
          return if stats.size is prevStats.size and 
            stats.mtime.getTime() is prevStats.mtime.getTime()
          prevStats = stats
          fs.readFile source, (err, code) ->
            throw err if err
            compileScript(source, code.toString(), base)

# Write out a JavaScript source file with the compiled code. By default, files
# are written out in `cwd` as `.js` files with the same name, but the output
# directory can be customized with `--output`.
writeJs = (source, js, base) ->
  filename  = path.basename(source, path.extname(source)) + '.js'
  srcDir    = path.dirname source
  baseDir   = if base is '.' then srcDir else srcDir.substring base.length
  dir       = if opts.output then path.join opts.output, baseDir else srcDir
  jsPath    = path.join dir, filename
  compile   = ->
    js = ' ' if js.length <= 0
    fs.writeFile jsPath, js, (err) ->
      if err
        printLine err.message
      else if opts.compile and opts.watch
        console.log "#{(new Date).toLocaleTimeString()} - compiled #{source}"
  path.exists dir, (exists) ->
    if exists then compile() else exec "mkdir -p #{dir}", compile

# Pipe compiled JS through JSLint (requires a working `jsl` command), printing
# any errors or warnings that arise.
lint = (file, js) ->
  printIt = (buffer) -> printLine file + ':\t' + buffer.toString().trim()
  conf = __dirname + '/../../extras/jsl.conf'
  jsl = spawn 'jsl', ['-nologo', '-stdin', '-conf', conf]
  jsl.stdout.on 'data', printIt
  jsl.stderr.on 'data', printIt
  jsl.stdin.write js
  jsl.stdin.end()

# Pretty-print a stream of tokens.
printTokens = (tokens) ->
  strings = for token in tokens
    [tag, value] = [token[0], token[1].toString().replace(/\n/, '\\n')]
    "[#{tag} #{value}]"
  printLine strings.join(' ')

# Use the [OptionParser module](optparse.html) to extract all options from
# `process.argv` that are specified in `SWITCHES`.
parseOptions = ->
  optionParser  = new optparse.OptionParser SWITCHES, BANNER
  o = opts      = optionParser.parse process.argv.slice 2
  o.compile     or=  !!o.output
  o.run         = not (o.compile or o.print or o.lint)
  o.print       = !!  (o.print or (o.eval or o.stdio and o.compile))
  sources       = o.arguments

# The compile-time options to pass to the CoffeeScript compiler.
compileOptions = (filename) -> {filename, bare: opts.bare}

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
