concatPages = (urls) ->
  string = ""
  for url in urls
    # fetchURL returns a 'thenable' A+/Promise object
    string += await fetchURL(url)
  string

concatPages([page, otherPage, yetAnother])
  .then (string) ->
    console.log "Concatenation result: #{string}"
