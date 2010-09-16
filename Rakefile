require 'erb'
require 'fileutils'
require 'rake/testtask'
require 'rubygems'
require 'yui/compressor'

HEADER = <<-EOS
/**
 * CoffeeScript Compiler v0.9.3
 * http://coffeescript.org
 *
 * Copyright 2010, Jeremy Ashkenas
 * Released under the MIT License
 */
EOS

desc "Build the documentation page"
task :doc do
  source = 'documentation/index.html.erb'
  child = fork { exec "bin/coffee --no-wrap -cw -o documentation/js documentation/coffee/*.coffee" }
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
  sources = %w(helpers.js rewriter.js lexer.js parser.js scope.js nodes.js coffee-script.js browser.js)
  code    = sources.map {|s| File.read('lib/' + s) }.join('')
  code    = YUI::JavaScriptCompressor.new.compress(code)
  File.open('extras/coffee-script.js', 'w+') {|f| f.write(HEADER + code) }
end

