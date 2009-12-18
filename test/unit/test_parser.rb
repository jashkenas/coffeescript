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
    nodes = @par.parse("a: 'one'").expressions
    assert nodes.length == 1
    assign = nodes.first
    assert assign.is_a? AssignNode
    assert assign.variable.literal == 'a'
  end

  def test_parsing_an_object_literal
    nodes = @par.parse("{one : 1 \n two : 2}").expressions
    obj = nodes.first.literal
    assert obj.is_a? ObjectNode
    assert obj.properties.first.variable == "one"
    assert obj.properties.last.variable == "two"
  end

  def test_parsing_an_function_definition
    code = @par.parse("x, y => x * y.").expressions.first
    assert code.params == ['x', 'y']
    body = code.body.expressions.first
    assert body.is_a? OpNode
    assert body.operator == '*'
  end

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
