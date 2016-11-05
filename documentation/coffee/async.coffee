sleep = (ms) ->
  new Promise (resolve) ->
    window.setTimeout resolve, ms

window.countdown = (seconds) ->
  for i in [seconds..1]
    alert("#{i} second(s) to go...")
    await sleep(1000)  # wait one second
  alert("done!")
