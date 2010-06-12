# The `coffee` utility. Handles command-line compilation of CoffeeScript
# into various forms: saved into `.js` files or printed to stdout, piped to
# [JSLint](http://javascriptlint.com/) or recompiled every time the source is
# saved, printed as a token stream or as the syntax tree, or launch an
# interactive REPL.

# External dependencies.
fs:            require 'fs'
path:          require 'path'
optparse:      require './optparse'
CoffeeScript:  require './coffee-script'
{spawn, exec}: require('child_process')

# The help banner that is printed when `coffee` is called without arguments.
BANNER: '''
  coffee compiles CoffeeScript source files into JavaScript.

  Usage:
    coffee path/to/script.coffee
        '''

# The list of all the valid option flags that `coffee` knows how to handle.
SWITCHES: [
  ['-c', '--compile',       'compile to JavaScript and save as .js files']
  ['-i', '--interactive',   'run an interactive CoffeeScript REPL']
  ['-o', '--output [DIR]',  'set the directory for compiled JavaScript']
  ['-w', '--watch',         'watch scripts for changes, and recompile']
  ['-p', '--print',         'print the compiled JavaScript to stdout']
  ['-l', '--lint',          'pipe the compiled JavaScript through JSLint']
  ['-s', '--stdio',         'listen for and compile scripts over stdio']
  ['-e', '--eval',          'compile a string from the command line']
  [      '--no-wrap',       'compile without the top-level function wrapper']
  ['-t', '--tokens',        'print the tokens that the lexer produces']
  ['-n', '--nodes',         'print the parse tree that Jison produces']
  ['-v', '--version',       'display CoffeeScript version']
  ['-h', '--help',          'display this help message']
]

# Top-level objects shared by all the functions.
options: {}
sources: []
optionParser: null

# Run `coffee` by parsing passed options and determining what action to take.
# Many flags cause us to divert before compiling anything. Flags passed after
# `--` will be passed verbatim to your script as arguments in `process.argv`
exports.run: ->
  parseOptions()
  return usage()                              if options.help
  return version()                            if options.version
  return require './repl'                     if options.interactive
  return compileStdio()                      if options.stdio
  return compileScript 'console', sources[0] if options.eval
  return require './repl'                     unless sources.length
  separator: sources.indexOf '--'
  flags: []
  if separator >= 0
    flags: sources[(separator + 1)...sources.length]
    sources: sources[0...separator]
  process.ARGV: process.argv: flags
  compileScripts()

# Asynchronously read in each CoffeeScript in a list of source files and
# compile them. If a directory is passed, recursively compile all
# '.coffee' extension source files in it and all subdirectories.
compileScripts: ->
  for source in sources
    base: source
    compile: (source, topLevel) ->
      path.exists source, (exists) ->
        throw new Error "File not found: $source" unless exists
        fs.stat source, (err, stats) ->
          if stats.isDirectory()
            fs.readdir source, (err, files) ->
              for file in files
                compile path.join(source, file)
          else if topLevel or path.extname(source) is '.coffee'
            fs.readFile source, (err, code) -> compileScript(source, code.toString(), base)
            watch source, base if options.watch
    compile source, true

# Compile a single source script, containing the given code, according to the
# requested options. If evaluating the script directly sets `__filename`,
# `__dirname` and `module.filename` to be correct relative to the script's path.
compileScript: (source, code, base) ->
  o: options
  codeOpts: compileOptions source
  try
    if      o.tokens      then printTokens CoffeeScript.tokens code
    else if o.nodes       then puts CoffeeScript.nodes(code).toString()
    else if o.run         then CoffeeScript.run code, codeOpts
    else
      js: CoffeeScript.compile code, codeOpts
      if o.print          then print js
      else if o.compile   then writeJs source, js, base
      else if o.lint      then lint js
  catch err
    error(err.stack) and process.exit 1 unless o.watch
    puts err.message

# Attach the appropriate listeners to compile scripts incoming over **stdin**,
# and write them back to **stdout**.
compileStdio: ->
  code: ''
  stdin: process.openStdin()
  stdin.addListener 'data', (buffer) ->
    code: + buffer.toString() if buffer
  stdin.addListener 'end', ->
    compileScript 'stdio', code

# Watch a source CoffeeScript file using `fs.watchFile`, recompiling it every
# time the file is updated. May be used in combination with other options,
# such as `--lint` or `--print`.
watch: (source, base) ->
  fs.watchFile source, {persistent: true, interval: 500}, (curr, prev) ->
    return if curr.mtime.getTime() is prev.mtime.getTime()
    puts "Compiled $source" if options.compile
    fs.readFile source, (err, code) -> compileScript(source, code.toString(), base)

# Write out a JavaScript source file with the compiled code. By default, files
# are written out in `cwd` as `.js` files with the same name, but the output
# directory can be customized with `--output`.
writeJs: (source, js, base) ->
  filename: path.basename(source, path.extname(source)) + '.js'
  srcDir:  path.dirname source
  baseDir: srcDir.substring base.length
  dir:      if options.output then path.join options.output, baseDir else srcDir
  jsPath:  path.join dir, filename
  compile:  -> fs.writeFile jsPath, js
  path.exists dir, (exists) ->
    if exists then compile() else exec "mkdir -p $dir", compile

# Pipe compiled JS through JSLint (requires a working `jsl` command), printing
# any errors or warnings that arise.
lint: (js) ->
  printIt: (buffer) -> print buffer.toString()
  jsl: spawn 'jsl', ['-nologo', '-stdin']
  jsl.stdout.addListener 'data', printIt
  jsl.stderr.addListener 'data', printIt
  jsl.stdin.write js
  jsl.stdin.end()

# Pretty-print a stream of tokens.
printTokens: (tokens) ->
  strings: for token in tokens
    [tag, value]: [token[0], token[1].toString().replace(/\n/, '\\n')]
    "[$tag $value]"
  puts strings.join(' ')

# Use the [OptionParser module](optparse.html) to extract all options from
# `process.argv` that are specified in `SWITCHES`.
parseOptions: ->
  optionParser: new optparse.OptionParser SWITCHES, BANNER
  o: options:    optionParser.parse(process.argv)
  options.run:   not (o.compile or o.print or o.lint)
  options.print: !!  (o.print or (o.eval or o.stdio and o.compile))
  sources:       options.arguments[2...options.arguments.length]

# The compile-time options to pass to the CoffeeScript compiler.
compileOptions: (source) ->
  o: {source: source}
  o['no_wrap']: options['no-wrap']
  o

# Print the `--help` usage message and exit.
usage: ->
  puts optionParser.help()
  process.exit 0

# Print the `--version` message and exit.
version: ->
  puts "CoffeeScript version $CoffeeScript.VERSION"
  process.exit 0
