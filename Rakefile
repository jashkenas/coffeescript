require 'erb'
require 'fileutils'
require 'rake/testtask'
require 'rubygems'
require 'closure-compiler'

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
  sources = %w(helpers rewriter lexer parser scope nodes coffee-script browser)
  code = sources.inject '' do |js, name|
    js << <<-"JS"
      require['./#{name}'] = new function(){
        var exports = this;
        #{ File.read "lib/#{name}.js" }
      }
    JS
  end
  code = Closure::Compiler.new.compress(<<-"JS")
    this.CoffeeScript = function(){
      function require(path){ return require[path] }
      #{ code }
      return require['./coffee-script']
    }()
  JS
  File.open('extras/coffee-script.js', 'wb+') {|f| f.write(HEADER + code) }
end
