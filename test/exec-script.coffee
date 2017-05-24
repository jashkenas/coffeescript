# return if global.testingBrowser
# nonBrowserTest ->

child_process = require 'child_process'

helpers = CoffeeScript.helpers

binary = require.resolve '../bin/coffee'

# shebangArgvs = [
#   [binary]
#   [binary, '--']
# ]

scriptArgvPrefixChoices = [
  # none
  []
  # one valid argument
  ['-b']
  # two valid arguments
  ['-b', '-j']
  # first invalid argument
  ['-x', '-j']
  # second invalid argument
  ['-b', '-x']
  # both invalid arguments
  ['-x', '-q']
  # argument with value
  ['-e', 'console.log process.argv']
]

scriptArgvJoinedChoices = [
  # none
  []
  # two valid arguments
  ['-cs']
  # first invalid argument
  ['-zc']
  # second invalid argument
  ['-cz']
  # two invalid arguments
  ['-yz']
]

scriptArgvDashChoices = [
  []
  ['--']
]

scriptArgvFileBasename = './exec-script/print-argv'
scriptArgvPathChoices = [
  []
  require.resolve "#{scriptArgvFileBasename}.coffee"
  require.resolve "#{scriptArgvFileBasename}.litcoffee"
]

scriptArgvs = helpers.allOrderedSeqs(
  # scriptArgvPathChoices,
  scriptArgvPrefixChoices,
  scriptArgvJoinedChoices,
  scriptArgvDashChoices,
  scriptArgvPathChoices)

p = (desc, obj) -> console.error "#{desc}: #{JSON.stringify obj}"

test "lol", ->
  for argList in scriptArgvs
    p 'argList', argList
    output = child_process.execFileSync binary, ['--', argList...]
    p 'output', output

# test "does not modify args with '--' argument to coffee exe", ->
#   for args in scriptArgvs
