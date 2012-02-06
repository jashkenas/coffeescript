
dns = require("dns");

do_one = (cb, host) ->
  await dns.resolve host, "A", defer(err, ip)
  if err
    console.log "ERROR! " + err
  else
    console.log host + " -> " + ip
  cb()

do_all = (lst) ->
  for h in lst
    await 
      do_one defer(), h

do_all process.argv.slice(2)
