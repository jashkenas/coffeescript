require 'test_helper'

class ExecutionTest < Test::Unit::TestCase

  NO_WARNINGS = /\A(0 error\(s\), 0 warning\(s\)\n)+\Z/
  ALLS_WELL   = /\A\n?(true\n)+\Z/m

  # This is by far the most important test. It evaluates all of the
  # CoffeeScript in test/fixtures/execution, ensuring that all our
  # syntax actually works.
  def test_execution_of_coffeescript
    sources = ['test/fixtures/execution/*.coffee'].join(' ')
    assert `bin/coffee -r #{sources}`.match(ALLS_WELL)
  end

  def test_lintless_coffeescript
    lint_results = `bin/coffee -l test/fixtures/execution/*.coffee`
    assert lint_results.match(NO_WARNINGS)
  end

  def test_lintless_examples
    lint_results = `bin/coffee -l examples/*.coffee`
    assert lint_results.match(NO_WARNINGS)
  end

  def test_lintless_documentation
    lint_results = `bin/coffee -l documentation/coffee/*.coffee`
    assert lint_results.match(NO_WARNINGS)
  end

end
