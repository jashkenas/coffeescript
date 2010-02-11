# Quickie script to compile and run all the files given as arguments.

process.mixin require 'sys'
coffee: require './coffee-script'

paths: process.ARGV
paths: paths[2...paths.length]

if paths.length
  coffee.ruby_compile_files paths, (js) -> eval(js)
else
  require './repl'
