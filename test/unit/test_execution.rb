require 'test_helper'

class ExecutionTest < Test::Unit::TestCase

  NO_WARNINGS = "0 error(s), 0 warning(s)"

  # This is by far the most important test. It evaluates all of the
  # CoffeeScript in test/fixtures/execution, ensuring that all our
  # syntax actually works.
  def test_execution_of_coffeescript
    sources = ['test/fixtures/execution/*.coffee'].join(' ')
    (`bin/coffee -r #{sources}`).split("\n").each do |line|
      assert line == "true"
    end
  end

  def test_lintless_coffeescript
    no_warnings `bin/coffee -l test/fixtures/execution/*.coffee`
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
