# Check if it can import a coffeescript-only module and check its output
ok (require 'test_module').foo is "bar"