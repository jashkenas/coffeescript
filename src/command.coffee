# The `coffee` utility. Handles command-line compilation of CoffeeScript
# into various forms: saved into `.js` files or printed to stdout, piped to
# [JSLint](http://javascriptlint.com/) or recompiled every time the source is
# saved, printed as a token stream or as the syntax tree, or launch an
# interactive REPL.

# External dependencies.
fs:           require 'fs'
path:         require 'path'
optparse:     require 'optparse'
CoffeeScript: require 'coffee-script'

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
option_parser: null

# Run `coffee` by parsing passed options and determining what action to take.
# Many flags cause us to divert before compiling anything. Flags passed after
# `--` will be passed verbatim to your script as arguments in `process.argv`
exports.run: ->
  parse_options()
  return usage()                              if options.help
  return version()                            if options.version
  return require 'repl'                       if options.interactive
  return compile_stdio()                      if options.stdio
  return compile_script 'console', sources[0] if options.eval
  return usage()                              unless sources.length
  separator: sources.indexOf '--'
  flags: []
  if separator >= 0
    flags: sources[(separator + 1)...sources.length]
    sources: sources[0...separator]
  process.ARGV: process.argv: flags
  watch_scripts() if options.watch
  compile_scripts()

# Asynchronously read in each CoffeeScript in a list of source files and
# compile them.
compile_scripts: ->
  compile: (source) ->
    path.exists source, (exists) ->
      throw new Error "File not found: $source" unless exists
      fs.readFile source, (err, code) -> compile_script(source, code)
  compile(source) for source in sources

# Compile a single source script, containing the given code, according to the
# requested options. Both compile_scripts and watch_scripts share this method
# in common. If evaluating the script directly sets `__filename`, `__dirname`
# and `module.filename` to be correct relative to the script's path.
compile_script: (source, code) ->
  o: options
  code_opts: compile_options source
  try
    if      o.tokens            then print_tokens CoffeeScript.tokens code
    else if o.nodes             then puts CoffeeScript.nodes(code).toString()
    else if o.run               then CoffeeScript.run code, code_opts
    else
      js: CoffeeScript.compile code, code_opts
      if      o.compile         then write_js source, js
      else if o.lint            then lint js
      else if o.print or o.eval then print js
  catch err
    if o.watch                  then puts err.message else throw err

# Attach the appropriate listeners to compile scripts incoming over **stdin**,
# and write them back to **stdout**.
compile_stdio: ->
  code: ''
  process.stdio.open()
  process.stdio.addListener 'data', (string) ->
    code += string if string
  process.stdio.addListener 'close', ->
    process.stdio.write CoffeeScript.compile code, compile_options('stdio')

# Watch a list of source CoffeeScript files using `fs.watchFile`, recompiling
# them every time the files are updated. May be used in combination with other
# options, such as `--lint` or `--print`.
watch_scripts: ->
  watch: (source) ->
    fs.watchFile source, {persistent: true, interval: 500}, (curr, prev) ->
      return if curr.mtime.getTime() is prev.mtime.getTime()
      fs.readFile source, (err, code) -> compile_script(source, code)
  watch(source) for source in sources

# Write out a JavaScript source file with the compiled code. By default, files
# are written out in `cwd` as `.js` files with the same name, but the output
# directory can be customized with `--output`.
write_js: (source, js) ->
  filename: path.basename(source, path.extname(source)) + '.js'
  dir:      options.output or path.dirname(source)
  js_path:  path.join dir, filename
  fs.writeFile js_path, js

# Pipe compiled JS through JSLint (requires a working `jsl` command), printing
# any errors or warnings that arise.
lint: (js) ->
  jsl: process.createChildProcess('jsl', ['-nologo', '-stdin'])
  jsl.addListener 'output', (result) ->
    puts result.replace(/\n/g, '') if result
  jsl.addListener 'error', (result) ->
    puts result if result
  jsl.write js
  jsl.close()

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
  options.run:   not (o.compile or o.print or o.lint or o.eval)
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
  puts "CoffeeScript version ${CoffeeScript.VERSION}"
  process.exit 0
