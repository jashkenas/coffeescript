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

result = opt.parse ['one', 'two', 'three', '-r', 'dir']

eq 5, result.arguments.length
eq '-r', result.arguments[3]

result = opt.parse ['--optional', '-r', 'folder', 'one', 'two']

ok result.optional
eq 'folder', result.required
eq 'one two', result.arguments.join ' '

result = opt.parse ['-l', 'one.txt', '-l', 'two.txt', 'three']

ok result.list instanceof Array
ok result.list.join(' ') is 'one.txt two.txt'
ok result.arguments.join(' ') is 'three'

