fs:           require 'fs'
path:         require 'path'
optparse:     require 'optparse'
CoffeeScript: require 'coffee-script'

BANNER: '''
  coffee compiles CoffeeScript source files into JavaScript.

  Usage:
    coffee path/to/script.coffee
        '''

SWITCHES: [
  ['-i', '--interactive',   'run an interactive CoffeeScript REPL']
  ['-r', '--run',           'compile and run a CoffeeScript']
  ['-o', '--output [DIR]',  'set the directory for compiled JavaScript']
  ['-w', '--watch',         'watch scripts for changes, and recompile']
  ['-p', '--print',         'print the compiled JavaScript to stdout']
  ['-l', '--lint',          'pipe the compiled JavaScript through JSLint']
  ['-s', '--stdio',         'listen for and compile scripts over stdio']
  ['-e', '--eval',          'compile a string from the command line']
  ['-n', '--no-wrap',       'compile without the top-level function wrapper']
  ['-t', '--tokens',        'print the tokens that the lexer produces']
  ['-tr','--tree',          'print the parse tree that Jison produces']
  ['-v', '--version',       'display CoffeeScript version']
  ['-h', '--help',          'display this help message']
]

options: {}
sources: []
option_parser: null

# The CommandLine handles all of the functionality of the `coffee` utility.
exports.run: ->
  parse_options()
  return usage()                              if options.help
  return version()                            if options.version
  return require 'repl'                       if options.interactive
  return compile_stdio()                      if options.stdio
  return compile_script 'unknown', sources[0] if options.eval
  return usage()                              unless sources.length
  separator: sources.indexOf '--'
  flags: []
  if separator >= 0
    flags: sources[(separator + 1)...sources.length]
    sources: sources[0...separator]
  process.ARGV = flags
  watch_scripts() if options.watch
  compile_scripts()
  this

# The "--help" usage message.
usage: ->
  puts '\n' + option_parser.help() + '\n'
  process.exit 0

# The "--version" message.
version: ->
  puts "CoffeeScript version " + CoffeeScript.VERSION
  process.exit 0

# Compiles the source CoffeeScript, returning the desired JavaScript, tokens,
# or JSLint results.
compile_scripts: ->
  compile: (source) ->
    fs.readFile source, (err, code) -> compile_script(source, code)
  compile(source) for source in sources

# Compile a single source script, containing the given code, according to the
# requested options. Both compile_scripts and watch_scripts share this method.
compile_script: (source, code) ->
  o: options
  try
    if      o.tokens            then print_tokens CoffeeScript.tokenize code
    else if o.tree              then puts CoffeeScript.tree(code).toString()
    else
      js: CoffeeScript.compile code, compile_options()
      if      o.run             then eval js
      else if o.lint            then lint js
      else if o.print or o.eval then print js
      else                           write_js source, js
  catch err
    if o.watch                  then puts err.message else throw err

# Listen for and compile scripts over stdio.
compile_stdio: ->
  code: ''
  process.stdio.open()
  process.stdio.addListener 'data', (string) ->
    code += string if string
  process.stdio.addListener 'close', ->
    process.stdio.write CoffeeScript.compile code, compile_options()

# Watch a list of source CoffeeScript files, recompiling them every time the
# files are updated.
watch_scripts: ->
  watch: (source) ->
    process.watchFile source, {persistent: true, interval: 500}, (curr, prev) ->
      return if curr.mtime.getTime() is prev.mtime.getTime()
      fs.readFile source, (err, code) -> compile_script(source, code)
  watch(source) for source in sources

# Write out a JavaScript source file with the compiled code.
write_js: (source, js) ->
  filename: path.basename(source, path.extname(source)) + '.js'
  dir:      options.output or path.dirname(source)
  js_path:  path.join dir, filename
  fs.writeFile js_path, js

# Pipe compiled JS through JSLint (requires a working 'jsl' command).
lint: (js) ->
  jsl: process.createChildProcess('jsl', ['-nologo', '-stdin'])
  jsl.addListener 'output', (result) ->
    puts result.replace(/\n/g, '') if result
  jsl.addListener 'error', (result) ->
    puts result if result
  jsl.write js
  jsl.close()

# Pretty-print a token stream.
print_tokens: (tokens) ->
  strings: for token in tokens
    '[' + token[0] + ' ' + token[1].toString().replace(/\n/, '\\n') + ']'
  puts strings.join(' ')

# Use OptionParser for all the options.
parse_options: ->
  option_parser: new optparse.OptionParser SWITCHES, BANNER
  options: option_parser.parse(process.ARGV)
  sources: options.arguments[2...options.arguments.length]

# The options to pass to the CoffeeScript compiler.
compile_options: ->
  if options['no-wrap'] then {no_wrap: true} else {}
