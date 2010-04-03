# Check if we can import and execute a CoffeeScript-only module successfully.
ok require('./test_module').func() is "from over there"