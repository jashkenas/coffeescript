# Recompile the Parser.
# With debugging and verbose: -v -g
`racc -o parser.rb grammar.y`

# Parse and print "code.jaa".
require "parser.rb"
js = Parser.new.parse(File.read('code.jaa')).compile
puts "\n\n"
puts js

# Pipe compiled JS through JSLint.
puts "\n\n"
require 'open3'
stdin, stdout, stderr = Open3.popen3('/Users/jashkenas/Library/Application\ Support/TextMate/Bundles/JavaScript\ Tools.tmbundle/Support/bin/jsl -nologo -stdin')
stdin.write(js)
stdin.close
puts stdout.read
stdout.close
stderr.close