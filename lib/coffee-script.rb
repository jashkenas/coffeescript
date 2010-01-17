$LOAD_PATH.unshift(File.dirname(__FILE__))
require "coffee_script/lexer"
require "coffee_script/parser"
require "coffee_script/nodes"
require "coffee_script/value"
require "coffee_script/scope"
require "coffee_script/rewriter"
require "coffee_script/parse_error"

# Namespace for all CoffeeScript internal classes.
module CoffeeScript

  VERSION = '0.2.6'   # Keep in sync with the gemspec.

  # Compile a script (String or IO) to JavaScript.
  def self.compile(script, options={})
    script = script.read if script.respond_to?(:read)
    Parser.new.parse(script).compile(options)
  end

end
