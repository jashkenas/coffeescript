sys = require('sys')
{inspect}    = require 'util'
assert = require('assert')

enableColours = no
unless process.platform is 'win32'
  enableColours = not process.env.NODE_DISABLE_COLORS


spawn = require('child_process').spawn

path = require('path')
testDir = path.dirname(__filename);

coffee_bin = path.join(testDir, '../bin/coffee');

console.log coffee_bin.toString()


coffee_repl = spawn(coffee_bin)



if typeof test isnt 'function' 
  test = (desc, fn) ->
    fn()

coffee_repl.stdout.on('data', (data) ->
  response = data.toString('ascii', 0, data.length)
  response = response.replace(/coffee> /g, '')
  test "testing ", ->
    assert.strictEqual(response,coffee_repl.expect)
  console.log 'Match'
  if (coffee_repl.list && coffee_repl.list.length > 0) 
          send_expect(coffee_repl.list);
  else 
          console.log('End of test, exiting.\n');
          process.exit();
        
)

send_expect = (list) ->
  if list.length > 0 
    cur = list.shift()

    console.log('sending ' + JSON.stringify(cur.send))

    cur.proc.expect = cur.expect
    cur.proc.list = list
    if (cur.send.length > 0) then cur.proc.stdin.write(cur.send) 
    

send_expect([
  proc: coffee_repl
  send: ''
  expect: ''
,
  proc: coffee_repl
  send: "test='test'", 
  expect: inspect('test', no, 2, enableColours) + '\n' 
,
  proc: coffee_repl
  send: 'song = ["do", "re", "mi", "fa", "so"]', 
  expect: inspect(["do", "re", "mi", "fa", "so"], no, 2, enableColours) + '\n' 
,
  proc: coffee_repl
  send: ':exit', 
  expect: "Exiting\n" 
  ]
)

timer = setTimeout( (->assert.fail('Timeout')),5000)




