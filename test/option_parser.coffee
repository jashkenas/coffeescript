# Option Parser
# -------------

# Ensure that the OptionParser handles arguments correctly.
return unless require?
{OptionParser} = require './../lib/coffeescript/optparse'

flags = [
  ['-r', '--required [DIR]',  'desc required']
  ['-o', '--optional',        'desc optional']
  ['-l', '--list [FILES*]',   'desc list']
]

banner = '''
  banner text
'''

opt = new OptionParser flags, banner

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

test "throw if multiple flags try to use the same short or long name", ->
  throws -> new OptionParser [
    ['-r', '--required [DIR]', 'required']
    ['-r', '--long',           'switch']
  ]

  throws -> new OptionParser [
    ['-a', '--append [STR]', 'append']
    ['-b', '--append',       'append with -b short opt']
  ]

  throws -> new OptionParser [
    ['--just-long', 'desc']
    ['--just-long', 'another desc']
  ]

  throws -> new OptionParser [
    ['-j', '--just-long', 'desc']
    ['--just-long', 'another desc']
  ]

  throws -> new OptionParser [
    ['--just-long',       'desc']
    ['-j', '--just-long', 'another desc']
  ]

reQuote = (str) -> (str ? '').replace /[.?*+^$[\]\\(){}|-]/g, "\\$&"

flagPattern = (flag) ->
  switch flag.length
    when 2
      shortFlag = null
      [longFlag, desc] = flag
    when 3
      [shortFlag, longFlag, desc] = flag
    else
      throw new Error "invalid flag"
  longFlagPat = reQuote longFlag.match(/--[^\s]+/)[0]
  descPat = reQuote desc
  if shortFlag?
    joined = [reQuote(shortFlag), longFlagPat, descPat].join '.*'
  else
    joined = [longFlagPat, descPat].join '.*'
  new RegExp "^.*#{joined}.*$", 'm'

test "help text shows banner and all switches", ->
  bannerHelp = opt.help()
  bannerPattern = new RegExp reQuote(banner), 'g'
  ok bannerHelp.match bannerPattern
  for flag in flags
    linePat = flagPattern flag
    ok bannerHelp.match linePat

test "help text shows switches, even without banner", ->
  parser = new OptionParser flags
  noBannerHelp = parser.help()
  for flag in flags
    linePat = flagPattern flag
    ok noBannerHelp.match linePat
