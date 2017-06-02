{buildCSOptionParser} = require '../lib/coffeescript/command'

optionParser = buildCSOptionParser()

sameOptions = (opts1, opts2, msg) ->
  ownKeys = Object.keys(opts1).sort()
  otherKeys = Object.keys(opts2).sort()
  arrayEq ownKeys, otherKeys, msg
  for k in ownKeys
    arrayEq opts1[k], opts2[k], msg
  yes

test "combined options are still split after initial file name", ->
  argv = ['some-file.coffee', '-bc']
  parsed = optionParser.parse argv
  expected = arguments: ['some-file.coffee', '-b', '-c']
  sameOptions parsed, expected

  argv = ['some-file.litcoffee', '-bc']
  parsed = optionParser.parse argv
  expected = arguments: ['some-file.litcoffee', '-b', '-c']
  sameOptions parsed, expected

  argv = ['-c', 'some-file.coffee', '-bc']
  parsed = optionParser.parse argv
  expected =
    compile: yes
    arguments: ['some-file.coffee', '-b', '-c']
  sameOptions parsed, expected

  argv = ['-bc', 'some-file.coffee', '-bc']
  parsed = optionParser.parse argv
  expected =
    bare: yes
    compile: yes
    arguments: ['some-file.coffee', '-b', '-c']
  sameOptions parsed, expected

test "combined options are not split after a '--'", ->
  argv = ['--', '-bc']
  parsed = optionParser.parse argv
  expected = arguments: ['-bc']
  sameOptions parsed, expected

  argv = ['-bc', '--', '-bc']
  parsed = optionParser.parse argv
  expected =
    bare: yes
    compile: yes
    arguments: ['-bc']
  sameOptions parsed, expected

test "options are not split after any '--'", ->
  argv = ['--', '--', '-bc']
  parsed = optionParser.parse argv
  expected = arguments: ['--', '-bc']
  sameOptions parsed, expected

  argv = ['--', 'some-file.coffee', '--', 'arg']
  parsed = optionParser.parse argv
  expected = arguments: ['some-file.coffee', '--', 'arg']
  sameOptions parsed, expected

  argv = ['--', 'arg', 'some-file.coffee', '--', '-bc']
  parsed = optionParser.parse argv
  expected = arguments: ['arg', 'some-file.coffee', '--', '-bc']
  sameOptions parsed, expected

test "later '--' are removed", ->
  argv = ['some-file.coffee', '--', '-bc']
  parsed = optionParser.parse argv
  expected = arguments: ['some-file.coffee', '-bc']
  sameOptions parsed, expected
