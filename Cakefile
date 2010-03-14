fs: require 'fs'
CoffeeScript: require 'coffee-script'

# Run a CoffeeScript through our node/coffee interpreter.
run: (args) ->
  proc: process.createChildProcess 'bin/coffee', args
  proc.addListener 'error', (err) -> if err then puts err


option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'

task 'install', 'install CoffeeScript into /usr/local (or --prefix)', (options) ->
  base: options.prefix or '/usr/local'
  lib:  base + '/lib/coffee-script'
  exec([
    'mkdir -p ' + lib
    'cp -rf bin lib LICENSE README package.json src vendor ' + lib
    'ln -sf ' + lib + '/bin/coffee ' + base + '/bin/coffee'
    'ln -sf ' + lib + '/bin/cake ' + base + '/bin/cake'
  ].join(' && '), (err, stdout, stderr) ->
   if err then print stderr
  )


task 'build', 'build the CoffeeScript language from source', ->
  files: fs.readdirSync 'src'
  files: 'src/' + file for file in files when file.match(/\.coffee$/)
  run ['-c', '-o', 'lib'].concat(files)


task 'build:full', 'rebuild the source twice, and run the tests', ->
  exec 'bin/cake build && bin/cake build && bin/cake test', (err, stdout, stderr) ->
    print stdout if stdout
    print stderr if stderr
    throw err    if err


task 'build:parser', 'rebuild the Jison parser (run build first)', ->
  require.paths.unshift 'vendor/jison/lib'
  parser: require('grammar').parser
  js: parser.generate()
  parser_path: 'lib/parser.js'
  fs.writeFile parser_path, js


task 'build:ultraviolet', 'build and install the Ultraviolet syntax highlighter', ->
  exec 'plist2syntax ../coffee-script-tmbundle/Syntaxes/CoffeeScript.tmLanguage', (err) ->
    throw err if err
    exec 'sudo mv coffeescript.yaml /usr/local/lib/ruby/gems/1.8/gems/ultraviolet-0.10.2/syntax/coffeescript.syntax'


task 'build:browser', 'rebuild the merged script for inclusion in the browser', ->
  exec 'rake browser', (err) ->
    throw err if err


task 'doc:site', 'watch and continually rebuild the documentation for the website', ->
  exec 'rake doc'


task 'doc:source', 'rebuild the internal documentation', ->
  exec 'docco src/*.coffee && cp -rf docs documentation && rm -r docs', (err) ->
    throw err if err


task 'doc:underscore', 'rebuild the Underscore.coffee documentation page', ->
  exec 'uv -s coffeescript -t idle -h examples/underscore.coffee > documentation/underscore.html'


task 'test', 'run the CoffeeScript language test suite', ->
  process.mixin require 'assert'
  test_count: 0
  start_time: new Date()
  [original_ok, original_throws]: [ok, throws]
  process.mixin {
    ok:     (args...) -> test_count += 1; original_ok(args...)
    throws: (args...) -> test_count += 1; original_throws(args...)
    CoffeeScript: CoffeeScript
  }
  process.addListener 'exit', ->
    time: ((new Date() - start_time) / 1000).toFixed(2)
    puts '\033[0;32mpassed ' + test_count + ' tests in ' + time + ' seconds\033[0m'
  fs.readdir 'test', (err, files) ->
    for file in files
      fs.readFile 'test/' + file, (err, code) ->
        CoffeeScript.run code, {source: file}