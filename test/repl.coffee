sys = require('sys')
{inspect}    = require 'util'
assert = require('assert')

# Find out if we need to test "colorized" output
enableColours = no
unless process.platform is 'win32'
  enableColours = not process.env.NODE_DISABLE_COLORS


spawn = require('child_process').spawn

path = require('path')
testDir = path.dirname(__filename);

# Find out where our "coffee" script is located relative to the test directory
coffee_bin = path.join(testDir, '../bin/coffee');

# Create our running REPL
coffee_repl = spawn(coffee_bin)


if typeof test isnt 'function' 
  test = (desc, fn) ->
    fn()


# Listen for output on stdout and compare it to what we say 
# we are expecting.

coffee_repl.stdout.on('data', (data) ->
  response = data.toString('ascii', 0, data.length)
  # strip out the prompt
  response = response.replace(/coffee> /g, '')
  test "testing ", ->
    assert.strictEqual(response,coffee_repl.expect)
  console.log coffee_repl.message
  if (coffee_repl.list && coffee_repl.list.length > 0) 
          # If there are more tests, send again
          send_expect(coffee_repl.list);
  else 
          console.log('End of test, exiting.\n');
          process.exit();
        
)

# This function creates test via a list in the format
# [
#   proc: (The REPL process)
#   send: (The command to send)
#   expect: (The output to expect)((Make sure to use inspect() if needed))
$   message: (A friendly message to display if the test passes)
# ]

send_expect = (list) ->
  if list.length > 0 
    # Pop out a test to run
    cur = list.shift()

    console.log('sending ' + JSON.stringify(cur.send))
    
    # Set variables on the REPL process to be used in the stout listener
    cur.proc.expect = cur.expect
    cur.proc.list = list
    cur.proc.message = cur.message
    if (cur.send.length > 0) then cur.proc.stdin.write(cur.send) 


#########
#DEFINE TESTS HERE
#########

send_expect([
  proc: coffee_repl
  send: ''
  expect: ''
  message: 'Success: coffee> prompt sent'
,
  proc: coffee_repl
  send: "test='test'", 
  expect: inspect('test', no, 2, enableColours) + '\n' 
  message: 'Success: simple one liner executed'
,
  proc: coffee_repl
  send: 'song = ["do", "re", "mi", "fa", "so"]', 
  expect: inspect(["do", "re", "mi", "fa", "so"], no, 2, enableColours) + '\n'
  message: 'Success: list compiled correctly'
,
  proc: coffee_repl
  send: ':exit', 
  expect: "Exiting\n" 
  message: 'Success: exit signal received'
  ]
)

# Set a timer to kill the process if it hangs
timer = setTimeout( (->assert.fail('Timeout')),5000)




