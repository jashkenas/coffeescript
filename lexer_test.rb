require "lexer"
p Lexer.new.tokenize(File.read('code.jaa'))
