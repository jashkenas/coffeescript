$LOAD_PATH.unshift(File.dirname(__FILE__))
require "coffee_script/lexer"
require "coffee_script/parser"
require "coffee_script/nodes"
require "coffee_script/value"
require "coffee_script/scope"
require "coffee_script/parse_error"

# Namespace for all CoffeeScript internal classes.
module CoffeeScript

  VERSION = '0.1.0'

  def self.compile(script)
    script = script.read if script.respond_to?(:read)
    Parser.new.parse(script).compile
  end

end
