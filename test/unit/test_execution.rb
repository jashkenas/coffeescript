require 'test_helper'

class ExecutionTest < Test::Unit::TestCase

  NO_WARNINGS = /\A(0 error\(s\), 0 warning\(s\)\n)+\Z/

  def test_execution_of_coffeescript
    `bin/coffee-script test/fixtures/execution/*.cs`
    sources = Dir['test/fixtures/execution/*.js'].map {|f| File.expand_path(f) }
    starting_place = File.expand_path(Dir.pwd)
    Dir.chdir('/Users/jashkenas/Desktop/Beauty/Code/v8')
    sources.each do |source|
      suceeded = `./shell #{source}`.chomp.to_sym == :true
      puts "failed: #{source}" unless suceeded
      assert suceeded
    end
  ensure
    Dir.chdir(starting_place)
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
