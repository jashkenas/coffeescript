require 'test_helper'

class ExecutionTest < Test::Unit::TestCase

  def test_execution_of_coffeescript
    `bin/coffee-script test/fixtures/execution/*.cs`
    sources = Dir['test/fixtures/execution/*.js'].map {|f| File.expand_path(f) }
    starting_place = File.expand_path(Dir.pwd)
    Dir.chdir('/Users/jashkenas/Desktop/Beauty/Code/v8')
    sources.each do |source|
      # puts `./shell #{source}`
      assert `./shell #{source}`.chomp.to_sym == :true
    end
  ensure
    Dir.chdir(starting_place)
  end

end
