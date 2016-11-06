sleep = (ms) ->
  new Promise (resolve) ->
    window.setTimeout resolve, ms

countdown = (seconds) ->
  for i in [seconds..1]
    if window.speechSynthesis?
      utterance = new SpeechSynthesisUtterance "#{i}"
      window.speechSynthesis.cancel() # cancel any prior utterances
      window.speechSynthesis.speak utterance
    console.log i
    await sleep 1000 # wait one second
  alert "Done! (Check the console!)"

countdown(3)
