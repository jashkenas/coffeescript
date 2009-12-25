require 'test_helper'

class ExecutionTest < Test::Unit::TestCase

  NO_WARNINGS = /\A(0 error\(s\), 0 warning\(s\)\n)+\Z/
  ALLS_WELL   = /\A\n?(true\n)+\Z/

  def test_execution_of_coffeescript
    sources = ['test/fixtures/execution/*.cs'].join(' ')
    assert `bin/coffee-script -r #{sources}`.match(ALLS_WELL)
  end

  def test_lintless_coffeescript
    lint_results = `bin/coffee-script -l test/fixtures/execution/*.cs`
    assert lint_results.match(NO_WARNINGS)
  end

  def test_lintless_examples
    lint_results = `bin/coffee-script -l examples/*.cs`
    assert lint_results.match(NO_WARNINGS)
  end

end
