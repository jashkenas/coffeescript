return unless require?

path = require 'path'
{ execFileSync, spawnSync } = require 'child_process'

# Get the folder containing the compiled `coffee` executable and make it the
# PATH so that `#!/usr/bin/env coffee` resolves to our locally built file.
coffeeBinFolder = path.dirname require.resolve '../bin/coffee'
# For some reason, Windows requires `coffee` to be executed as `node coffee`.
coffeeCommand = if isWindows() then 'node coffee' else 'coffee'
spawnOptions =
  cwd: coffeeBinFolder
  encoding: 'utf8'
  env:
    PATH: coffeeBinFolder + (if isWindows() then ';' else ':') + process.env.PATH
  shell: isWindows()

shebangScript = require.resolve './importing/shebang.coffee'
initialSpaceScript = require.resolve './importing/shebang_initial_space.coffee'
extraArgsScript = require.resolve './importing/shebang_extra_args.coffee'
initialSpaceExtraArgsScript = require.resolve './importing/shebang_initial_space_extra_args.coffee'

test "parse arguments for shebang scripts correctly (on *nix platforms)", ->
  return if isWindows()

  stdout = execFileSync shebangScript, ['-abck'], spawnOptions
  expectedArgs = ['coffee', shebangScript, '-abck']
  realArgs = JSON.parse stdout
  arrayEq expectedArgs, realArgs

  stdout = execFileSync initialSpaceScript, ['-abck'], spawnOptions
  expectedArgs = ['coffee', initialSpaceScript, '-abck']
  realArgs = JSON.parse stdout
  arrayEq expectedArgs, realArgs

test "warn and remove -- if it is the second positional argument", ->
  result = spawnSync coffeeCommand, [shebangScript, '--'], spawnOptions
  stderr = result.stderr.toString()
  arrayEq JSON.parse(result.stdout), ['coffee', shebangScript]
  ok stderr.match /^coffee was invoked with '--'/m
  posArgs = stderr.match(/^The positional arguments were: (.*)$/m)[1]
  arrayEq JSON.parse(posArgs), [shebangScript, '--']
  ok result.status is 0

  result = spawnSync coffeeCommand, ['-b', shebangScript, '--'], spawnOptions
  stderr = result.stderr.toString()
  arrayEq JSON.parse(result.stdout), ['coffee', shebangScript]
  ok stderr.match /^coffee was invoked with '--'/m
  posArgs = stderr.match(/^The positional arguments were: (.*)$/m)[1]
  arrayEq JSON.parse(posArgs), [shebangScript, '--']
  ok result.status is 0

  result = spawnSync(
    coffeeCommand, ['-b', shebangScript, '--', 'ANOTHER'], spawnOptions)
  stderr = result.stderr.toString()
  arrayEq JSON.parse(result.stdout), ['coffee', shebangScript, 'ANOTHER']
  ok stderr.match /^coffee was invoked with '--'/m
  posArgs = stderr.match(/^The positional arguments were: (.*)$/m)[1]
  arrayEq JSON.parse(posArgs), [shebangScript, '--', 'ANOTHER']
  ok result.status is 0

  result = spawnSync(
    coffeeCommand, ['--', initialSpaceScript, 'arg'], spawnOptions)
  expectedArgs = ['coffee', initialSpaceScript, 'arg']
  realArgs = JSON.parse result.stdout
  arrayEq expectedArgs, realArgs
  ok result.stderr.toString() is ''
  ok result.status is 0

test "warn about non-portable shebang lines", ->
  result = spawnSync coffeeCommand, [extraArgsScript, 'arg'], spawnOptions
  stderr = result.stderr.toString()
  arrayEq JSON.parse(result.stdout), ['coffee', extraArgsScript, 'arg']
  ok stderr.match /^The script to be run begins with a shebang line with more than one/m
  [_, firstLine, file] = stderr.match(/^The shebang line was: '([^']+)' in file '([^']+)'/m)
  ok (firstLine is '#!/usr/bin/env coffee --')
  ok (file is extraArgsScript)
  args = stderr.match(/^The arguments were: (.*)$/m)[1]
  arrayEq JSON.parse(args), ['coffee', '--']
  ok result.status is 0

  result = spawnSync coffeeCommand, [initialSpaceScript, 'arg'], spawnOptions
  stderr = result.stderr.toString()
  ok stderr is ''
  arrayEq JSON.parse(result.stdout), ['coffee', initialSpaceScript, 'arg']
  ok result.status is 0

  result = spawnSync(
    coffeeCommand, [initialSpaceExtraArgsScript, 'arg'], spawnOptions)
  stderr = result.stderr.toString()
  arrayEq JSON.parse(result.stdout), ['coffee', initialSpaceExtraArgsScript, 'arg']
  ok stderr.match /^The script to be run begins with a shebang line with more than one/m
  [_, firstLine, file] = stderr.match(/^The shebang line was: '([^']+)' in file '([^']+)'/m)
  ok (firstLine is '#! /usr/bin/env coffee extra')
  ok (file is initialSpaceExtraArgsScript)
  args = stderr.match(/^The arguments were: (.*)$/m)[1]
  arrayEq JSON.parse(args), ['coffee', 'extra']
  ok result.status is 0

test "both warnings will be shown at once", ->
  result = spawnSync(
    coffeeCommand, [initialSpaceExtraArgsScript, '--', 'arg'], spawnOptions)
  stderr = result.stderr.toString()
  arrayEq JSON.parse(result.stdout), ['coffee', initialSpaceExtraArgsScript, 'arg']
  ok stderr.match /^The script to be run begins with a shebang line with more than one/m
  [_, firstLine, file] = stderr.match(/^The shebang line was: '([^']+)' in file '([^']+)'/m)
  ok (firstLine is '#! /usr/bin/env coffee extra')
  ok (file is initialSpaceExtraArgsScript)
  args = stderr.match(/^The arguments were: (.*)$/m)[1]
  arrayEq JSON.parse(args), ['coffee', 'extra']
  ok stderr.match /^coffee was invoked with '--'/m
  posArgs = stderr.match(/^The positional arguments were: (.*)$/m)[1]
  arrayEq JSON.parse(posArgs), [initialSpaceExtraArgsScript, '--', 'arg']
  ok result.status is 0
