require 'test_helper'

class ExecutionTest < Test::Unit::TestCase

  NO_WARNINGS = /\A(0 error\(s\), 0 warning\(s\)\n)+\Z/

  def test_execution_of_coffeescript
    Dir['test/fixtures/execution/*.cs'].each do |source|
      suceeded = `bin/cs #{source}`.chomp.to_sym == :true
      puts "failed: #{source}" unless suceeded
      assert suceeded
    end
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
