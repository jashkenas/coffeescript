require 'test_helper'

class LexerTest < Test::Unit::TestCase

  def setup
    @lex = Lexer.new
  end

  def test_lexing_an_empty_string
    assert @lex.tokenize("") == []
  end

  def test_lexing_basic_assignment
    code = "a: 'one'\nb: [1, 2]"
    assert @lex.tokenize(code) == [[:IDENTIFIER, "a"], [:ASSIGN, ":"],
      [:STRING, "'one'"], ["\n", "\n"], [:IDENTIFIER, "b"], [:ASSIGN, ":"],
      ["[", "["], [:NUMBER, "1"], [",", ","], [:NUMBER, "2"], ["]", "]"],
      ["\n", "\n"]]
  end

  def test_lexing_object_literal
    code = "{one : 1}"
    assert @lex.tokenize(code) == [["{", "{"], [:IDENTIFIER, "one"], [:ASSIGN, ":"],
      [:NUMBER, "1"], ["}", "}"], ["\n", "\n"]]
  end

  def test_lexing_function_definition
    code = "(x, y) -> x * y"
    assert @lex.tokenize(code) == [[:PARAM_START, "("], [:PARAM, "x"],
      [",", ","], [:PARAM, "y"], [:PARAM_END, ")"],
      ["->", "->"], [:INDENT, 2], [:IDENTIFIER, "x"], ["*", "*"],
      [:IDENTIFIER, "y"], [:OUTDENT, 2], ["\n", "\n"]]
  end

  def test_lexing_if_statement
    code = "clap_your_hands() if happy"
    assert @lex.tokenize(code) == [[:IDENTIFIER, "clap_your_hands"], [:CALL_START, "("],
      [:CALL_END, ")"], [:IF, "if"], [:IDENTIFIER, "happy"], ["\n", "\n"]]
  end

  def test_lexing_comment
    code = "a: 1\n# comment\n# on two lines\nb: 2"
    assert @lex.tokenize(code) == [[:IDENTIFIER, "a"], [:ASSIGN, ":"], [:NUMBER, "1"],
      ["\n", "\n"], [:COMMENT, [" comment", " on two lines"]], ["\n", "\n"],
      [:IDENTIFIER, "b"], [:ASSIGN, ":"], [:NUMBER, "2"], ["\n", "\n"]]
  end

  def test_lexing_newline_escaper
    code = "two: 1 + \\\n\n 1"
    assert @lex.tokenize(code) == [[:IDENTIFIER, "two"], [:ASSIGN, ":"],
      [:NUMBER, "1"], ["+", "+"], [:NUMBER, "1"], ["\n", "\n"]]
  end

  def test_lexing
    tokens = @lex.tokenize(File.read('test/fixtures/generation/each.coffee'))
    assert tokens.inspect == File.read('test/fixtures/generation/each.tokens')
  end

end
