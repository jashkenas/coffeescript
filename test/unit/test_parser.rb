require 'test_helper'

class ParserTest < Test::Unit::TestCase

  def setup
    @par = Parser.new
  end

  def test_parsing_an_empty_string
    nodes = @par.parse("")
    assert nodes.is_a? Expressions
    assert nodes.expressions.empty?
  end

  def test_parsing_a_basic_assignment
    nodes = @par.parse("a: 'one'")
    assert nodes.expressions.length == 1
    assign = nodes.expressions.first
    assert assign.is_a? AssignNode
    assert assign.variable.name == 'a'
  end
  #
  # def test_lexing_object_literal
  #   code = "{one : 1}"
  #   assert @lex.tokenize(code) == [["{", "{"], [:IDENTIFIER, "one"], [":", ":"],
  #     [:NUMBER, "1"], ["}", "}"]]
  # end
  #
  # def test_lexing_function_definition
  #   code = "x => x * x."
  #   assert @lex.tokenize(code) == [[:PARAM, "x"], ["=>", "=>"],
  #     [:IDENTIFIER, "x"], ["*", "*"], [:IDENTIFIER, "x"], [".", "."]]
  # end
  #
  # def test_lexing_if_statement
  #   code = "clap_your_hands() if happy"
  #   assert @lex.tokenize(code) == [[:IDENTIFIER, "clap_your_hands"], ["(", "("],
  #     [")", ")"], [:IF, "if"], [:IDENTIFIER, "happy"]]
  # end
  #
  # def test_lexing
  #   tokens = @lex.tokenize(File.read('test/fixtures/each.cs'))
  #   assert tokens.inspect == File.read('test/fixtures/each.tokens')
  # end

end
