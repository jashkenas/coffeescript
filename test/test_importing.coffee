# Check if we can import and execute a CoffeeScript-only module successfully.
if require?.extensions? or require?.registerExtension?
  ok require('./test_module').func() is "from over there"
