require "lexer"
p Lexer.new.tokenize(File.read('documents.jaa'))
