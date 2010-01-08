require 'test_helper'

class ParserTest < Test::Unit::TestCase

  def setup
    @par = Parser.new
  end

  def test_parsing_an_empty_string
    nodes = @par.parse("")
    assert nodes.is_a?(Expressions)
    assert nodes.expressions.empty?
  end

  def test_parsing_a_basic_assignment
    nodes = @par.parse("a: 'one'").expressions
    assert nodes.length == 1
    assign = nodes.first
    assert assign.is_a?(AssignNode)
    assert assign.variable.literal == 'a'
  end

  def test_parsing_an_object_literal
    nodes = @par.parse("{one : 1\ntwo : 2}").expressions
    obj = nodes.first.literal
    assert obj.is_a?(ObjectNode)
    assert obj.properties.first.variable.literal.value == "one"
    assert obj.properties.last.variable.literal.value == "two"
  end

  def test_parsing_an_function_definition
    code = @par.parse("x, y => x * y").expressions.first
    assert code.params == ['x', 'y']
    body = code.body.expressions.first
    assert body.is_a?(OpNode)
    assert body.operator == '*'
  end

  def test_parsing_if_statement
    the_if = @par.parse("clap_your_hands() if happy").expressions.first
    assert the_if.is_a?(IfNode)
    assert the_if.condition.literal == 'happy'
    assert the_if.body.is_a?(CallNode)
    assert the_if.body.variable.literal == 'clap_your_hands'
  end

  def test_parsing_array_comprehension
    nodes = @par.parse("i for x, i in [10, 9, 8, 7, 6, 5] when i % 2 is 0").expressions
    assert nodes.first.is_a?(ForNode)
    assert nodes.first.body.literal == 'i'
    assert nodes.first.filter.operator == '==='
    assert nodes.first.source.literal.objects.last.literal.value == "5"
  end

  def test_parsing_comment
    nodes = @par.parse("a: 1\n# comment\nb: 2").expressions
    assert nodes[1].is_a?(CommentNode)
  end

  def test_parsing_inner_comments
    nodes = @par.parse(File.read('test/fixtures/generation/inner_comments.coffee'))
    assert nodes.compile == File.read('test/fixtures/generation/inner_comments.js')
  end

  def test_parsing
    nodes = @par.parse(File.read('test/fixtures/generation/each.coffee'))
    assign = nodes.expressions[1]
    assert assign.is_a?(AssignNode)
    assert assign.variable.literal == '_'
    assert assign.value.is_a?(CodeNode)
    assert assign.value.params == ['obj', 'iterator', 'context']
  end

end
