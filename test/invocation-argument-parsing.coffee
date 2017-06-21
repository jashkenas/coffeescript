return unless require?

path = require 'path'
{execFileSync} = require 'child_process'

test "parses arguments for shebang scripts correctly (on unix platforms)", ->
  return if isWindows()

  # Get directory containing the compiled `coffee` executable and prepend it to
  # the path so `#!/usr/bin/env coffee` resolves to our locally built file.
  coffeeBinDir = path.dirname require.resolve('../bin/coffee')
  newPath = "#{coffeeBinDir}:#{process.env.PATH}"
  newEnv = Object.assign {}, process.env, {PATH: newPath}

  shebangScript = require.resolve './importing/shebang.coffee'
  stdout = execFileSync shebangScript, ['-abck'], {env: newEnv}

  expectedArgs = ['coffee', shebangScript, '-abck']
  realArgs = JSON.parse stdout
  arrayEq expectedArgs, realArgs
