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
  ['-m', '--monitor',       'show a message every time a script is compiled']
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
base: ''
is_watched: {}
option_parser: null

# Run `coffee` by parsing passed options and determining what action to take.
# Many flags cause us to divert before compiling anything. Flags passed after
# `--` will be passed verbatim to your script as arguments in `process.argv`
exports.run: ->
  parse_options()
  return usage()                              if options.help
  return version()                            if options.version
  return require './repl'                     if options.interactive
  return compile_stdio()                      if options.stdio
  return compile_script 'console', sources[0] if options.eval
  return usage()                              unless sources.length
  separator: sources.indexOf '--'
  flags: []
  if separator >= 0
    flags: sources[(separator + 1)...sources.length]
    sources: sources[0...separator]
  process.ARGV: process.argv: flags
  compile_scripts()

# Asynchronously read in each CoffeeScript in a list of source files and
# compile them. If a directory is passed, recursively compile all source
# files in it and all subdirectories.
compile_scripts: ->
  compile: (source) ->
    return                                    if is_watched[source]
    path.exists source, (exists) ->
      throw new Error "File not found: $source" unless exists
      fs.stat source, (err, stats) ->
        if stats.isDirectory()
          fs.readdir source, (err, files) ->
            for file in files
              compile path.join(source, file)
        else if source == base or path.extname(source) == '.coffee'
          puts 'Compiling ' + source                    if options.monitor
          fs.readFile source, (err, code) -> compile_script(source, code)
          watch(source) if options.watch

  run: ->
    for source in sources
      base = source
      compile(source)

  run()
  if options.watch
    setInterval run, 500

# Compile a single source script, containing the given code, according to the
# requested options. Both compile_scripts and watch_scripts share this method
# in common. If evaluating the script directly sets `__filename`, `__dirname`
# and `module.filename` to be correct relative to the script's path.
compile_script: (source, code) ->
  o: options
  code_opts: compile_options source
  try
    if      o.tokens      then print_tokens CoffeeScript.tokens code
    else if o.nodes       then puts CoffeeScript.nodes(code).toString()
    else if o.run         then CoffeeScript.run code, code_opts
    else
      js: CoffeeScript.compile code, code_opts
      if o.print          then print js
      else if o.compile   then write_js source, js
      else if o.lint      then lint js
  catch err
    if o.watch            then puts err.message else throw err

# Attach the appropriate listeners to compile scripts incoming over **stdin**,
# and write them back to **stdout**.
compile_stdio: ->
  code: ''
  stdin: process.openStdin()
  stdin.addListener 'data', (buffer) ->
    code: + buffer.toString() if buffer
  stdin.addListener 'end', ->
    compile_script 'stdio', code

# Watch a source CoffeeScript file using `fs.watchFile`, recompiling it every
# time the file is updated. May be used in combination with other options,
# such as `--lint` or `--print`.
watch: (source) ->
  is_watched[source] = true
  fs.watchFile source, {persistent: true, interval: 500}, (curr, prev) ->
    return if curr.mtime.getTime() is prev.mtime.getTime()
    puts 'Recompiling ' + source              if options.monitor
    fs.readFile source, (err, code) -> compile_script(source, code)

# Write out a JavaScript source file with the compiled code. By default, files
# are written out in `cwd` as `.js` files with the same name, but the output
# directory can be customized with `--output`.
write_js: (source, js) ->
  filename: path.basename(source, path.extname(source)) + '.js'
  src_dir:  path.dirname(source)
  dir: if options.output then \
    path.join options.output, src_dir.substring(base.length) else src_dir
  js_path:  path.join dir, filename
  exec "mkdir -p $dir", (error, stdout, stderr) -> fs.writeFile js_path, js

# Pipe compiled JS through JSLint (requires a working `jsl` command), printing
# any errors or warnings that arise.
lint: (js) ->
  print_it: (buffer) -> print buffer.toString()
  jsl: spawn 'jsl', ['-nologo', '-stdin']
  jsl.stdout.addListener 'data', print_it
  jsl.stderr.addListener 'data', print_it
  jsl.stdin.write js
  jsl.stdin.end()

# Pretty-print a stream of tokens.
print_tokens: (tokens) ->
  strings: for token in tokens
    [tag, value]: [token[0], token[1].toString().replace(/\n/, '\\n')]
    "[$tag $value]"
  puts strings.join(' ')

# Use the [OptionParser module](optparse.html) to extract all options from
# `process.argv` that are specified in `SWITCHES`.
parse_options: ->
  option_parser: new optparse.OptionParser SWITCHES, BANNER
  o: options:    option_parser.parse(process.argv)
  options.run:   not (o.compile or o.print or o.lint)
  options.print: !!  (o.print or (o.eval or o.stdio and o.compile))
  sources:       options.arguments[2...options.arguments.length]

# The compile-time options to pass to the CoffeeScript compiler.
compile_options: (source) ->
  o: {source: source}
  o['no_wrap']: options['no-wrap']
  o

# Print the `--help` usage message and exit.
usage: ->
  puts option_parser.help()
  process.exit 0

# Print the `--version` message and exit.
version: ->
  puts "CoffeeScript version $CoffeeScript.VERSION"
  process.exit 0
