# Ensure that the OptionParser handles arguments correctly.
return unless require?
{OptionParser} = require './../lib/optparse'

opt = new OptionParser [
  ['-r', '--required [DIR]',  'desc required']
  ['-o', '--optional',        'desc optional']
  ['-l', '--list [FILES*]',   'desc list']
]

result = opt.parse ['one', 'two', 'three', '-r', 'dir']

ok result.arguments.length is 5
ok result.arguments[3] is '-r'

result = opt.parse ['--optional', '-r', 'folder', 'one', 'two']

ok result.optional is true
ok result.required is 'folder'
ok result.arguments.join(' ') is 'one two'

result = opt.parse ['-l', 'one.txt', '-l', 'two.txt', 'three']

ok result.list instanceof Array
ok result.list.join(' ') is 'one.txt two.txt'
ok result.arguments.join(' ') is 'three'

