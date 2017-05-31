p = (desc, obj) -> console.error "#{desc}: #{JSON.stringify obj}"

test "options are split after initial file name", ->
  for argList in scriptArgvs
    p 'argList', argList
    output = child_process.execFileSync binary, ['--', argList...]
    p 'output', output
