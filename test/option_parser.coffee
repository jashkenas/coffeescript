# Option Parser
# -------------

# TODO: refactor option parser tests

# Ensure that the OptionParser handles arguments correctly.
return unless require?
{OptionParser} = require './../lib/coffee-script/optparse'

opt = new OptionParser [
  ['-r', '--required [DIR]',  'desc required']
  ['-o', '--optional',        'desc optional']
  ['-l', '--list [FILES*]',   'desc list']
]

test "basic arguments", ->
  args = ['one', 'two', 'three', '-r', 'dir']
  result = opt.parse args
  arrayEq args, result.arguments
  eq undefined, result.required

test "boolean and parameterised options", ->
  result = opt.parse ['--optional', '-r', 'folder', 'one', 'two']
  ok result.optional
  eq 'folder', result.required
  arrayEq ['one', 'two'], result.arguments

test "list options", ->
  result = opt.parse ['-l', 'one.txt', '-l', 'two.txt', 'three']
  arrayEq ['one.txt', 'two.txt'], result.list
  arrayEq ['three'], result.arguments

test "-- and interesting combinations", ->
  result = opt.parse ['-o','-r','a','-r','b','-o','--','-a','b','--c','d']
  arrayEq ['-a', 'b', '--c', 'd'], result.arguments
  ok result.optional
  eq 'b', result.required

  args = ['--','-o','a','-r','c','-o','--','-a','arg0','-b','arg1']
  result = opt.parse args
  eq undefined, result.optional
  eq undefined, result.required
  arrayEq args[1..], result.arguments
