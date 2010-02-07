require 'test_helper'

class ExecutionTest < Test::Unit::TestCase

  NO_WARNINGS = "0 error(s), 0 warning(s)"

  SOURCES = [
    'test/fixtures/execution/*.coffee',
    'examples/beautiful_code/*.coffee',
    'examples/computer_science/*.coffee'
  ]

  # This is by far the most important test. It evaluates all of the
  # CoffeeScript in test/fixtures/execution, as well as examples/beautiful_code,
  # ensuring that all our syntax actually works.
  def test_execution_of_coffeescript
    (`bin/coffee -r #{SOURCES.join(' ')}`).split("\n").each do |line|
      assert line == "true"
    end
  end

  # Test all of the code examples under Narwhal as well.
  def test_execution_with_narwhal
    (`bin/coffee -r --narwhal #{SOURCES.join(' ')}`).split("\n").each do |line|
      assert line == "true"
    end
  end

  def test_lintless_tests
    no_warnings `bin/coffee -l test/fixtures/*/*.coffee`
  end

  def test_lintless_examples
    no_warnings `bin/coffee -l examples/*.coffee`
  end

  def test_lintless_documentation
    no_warnings `bin/coffee -l documentation/coffee/*.coffee`
  end


  private

  def no_warnings(output)
    output.split("\n").each {|line| assert line == NO_WARNINGS }
  end

end
