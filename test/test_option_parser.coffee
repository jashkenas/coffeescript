# Ensure that the OptionParser handles arguments correctly.

{OptionParser}: require './../lib/optparse'

opt: new OptionParser [
  ['-r', '--required [DIR]',  'desc required']
  ['-o', '--optional',        'desc optional']
]

result: opt.parse ['one', 'two', 'three', '-r', 'dir']

ok result.arguments.length is 5
ok result.arguments[3] is '-r'

result: opt.parse ['--optional', '-r', 'folder', 'one', 'two']

ok result.optional is true
ok result.required is 'folder'
ok result.arguments.join(' ') is 'one two'

