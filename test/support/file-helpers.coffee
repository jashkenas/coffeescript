# NOTE: unused!!!
# throw new Error 'cannot make temporary file in browser' if inBrowser()

# fs = require 'fs'
# os = require 'os'
# path = require 'path'

# makeTmpDir = ->
#   tmpBase = path.normalize(os.tmpdir() + path.sep)
#   fs.mkdtempSync tmpBase

# # lazy single unique output directory over test run
# tmpDir = null

# # ensures files made with makeTmpFile are unique
# counter = 0

# makeTmpFile = (opts = {}) ->
#   {
#     description = 'gen',
#     suffix = '.coffee',
#     contents = '',
#     encoding,
#     executable = no
#   } = opts

#   prefix = (counter++).toString()
#   fname = "#{prefix}-#{description}#{suffix}"

#   tmpDir ?= makeTmpDir()
#   fpath = path.join tmpDir, fname
#   toWrite = contents ? ''

#   fs.writeFileSync fpath, toWrite, {encoding, flag: 'wx+'}
#   fs.chmodSync fpath, 0o0700 if executable
#   fpath

# coffeeExeFile = -> require.resolve '../../bin/coffee'

# exports = {makeTmpFile, coffeeExeFile}
