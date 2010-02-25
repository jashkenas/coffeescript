require 'erb'
require 'fileutils'
require 'rake/testtask'
require 'rubygems'
require 'closure-compiler'

desc "Build the documentation page"
task :doc do
  source = 'documentation/index.html.erb'
  child = fork { exec "bin/coffee documentation/coffee/*.coffee -o documentation/js -w" }
  at_exit { Process.kill("INT", child) }
  Signal.trap("INT") { exit }
  loop do
    mtime = File.stat(source).mtime
    if !@mtime || mtime > @mtime
      rendered = ERB.new(File.read(source)).result(binding)
      File.open('index.html', 'w+') {|f| f.write(rendered) }
    end
    @mtime = mtime
    sleep 1
  end
end

desc "Build the single concatenated and minified script for the browser"
task :browser do
  sources = %w(rewriter.js lexer.js parser.js scope.js nodes.js coffee-script.js)
  code    = sources.map {|s| File.read('lib/' + s) }.join('')
  code    = Closure::Compiler.new.compile(code)
  File.open('extras/coffee-script.js', 'w+') {|f| f.write(code) }
end

