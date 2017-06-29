return unless require?

path = require 'path'
{spawnSync, execFileSync} = require 'child_process'

# Get directory containing the compiled `coffee` executable and prepend it to
# the path so `#!/usr/bin/env coffee` resolves to our locally built file.
coffeeBinDir = path.dirname require.resolve('../bin/coffee')
patchedPath = "#{coffeeBinDir}:#{process.env.PATH}"
patchedEnv = Object.assign {}, process.env, {PATH: patchedPath}
shebangScript = require.resolve './importing/shebang.coffee'

test "parses arguments for shebang scripts correctly (on unix platforms)", ->
  return if isWindows()

  stdout = execFileSync shebangScript, ['-abck'], {env: patchedEnv}

  expectedArgs = ['coffee', shebangScript, '-abck']
  realArgs = JSON.parse stdout
  arrayEq expectedArgs, realArgs

test "warns and removes -- if it is the second positional argument", ->
  result = spawnSync 'coffee', [shebangScript, '--'], {env: patchedEnv}
  stderr = result.stderr.toString()
  arrayEq JSON.parse(result.stdout), ['coffee', shebangScript]
  ok stderr.match /^coffee was invoked with '--'/m
  posArgs = stderr.match(/^The positional arguments were: (.*)$/m)[1]
  arrayEq JSON.parse(posArgs), [shebangScript, '--']

  result = spawnSync 'coffee', ['-b', shebangScript, '--'], {env: patchedEnv}
  stderr = result.stderr.toString()
  arrayEq JSON.parse(result.stdout), ['coffee', shebangScript]
  ok stderr.match /^coffee was invoked with '--'/m
  posArgs = stderr.match(/^The positional arguments were: (.*)$/m)[1]
  arrayEq JSON.parse(posArgs), [shebangScript, '--']

  result = spawnSync(
    'coffee', ['-b', shebangScript, '--', 'ANOTHER ONE'], {env: patchedEnv})
  stderr = result.stderr.toString()
  arrayEq JSON.parse(result.stdout), ['coffee', shebangScript, 'ANOTHER ONE']
  ok stderr.match /^coffee was invoked with '--'/m
  posArgs = stderr.match(/^The positional arguments were: (.*)$/m)[1]
  arrayEq JSON.parse(posArgs), [shebangScript, '--', 'ANOTHER ONE']
