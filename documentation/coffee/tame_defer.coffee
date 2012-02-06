dns = require 'dns' # Use node.js's DNS resolution system
for host in [ 'yahoo.com', 'google.com', 'nytimes.com']
  await dns.resolve host, "A", defer err, ip
  if err then console.log "Error for #{host}: #{err}"
  else        console.log "Resolved  #{host} -> #{ip}"
  
