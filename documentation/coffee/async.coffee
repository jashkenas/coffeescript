sleep = (ms) ->
  new Promise (resolve) ->
    window.setTimeout resolve, ms

window.countdown = (seconds) ->
  if not window.speechSynthesis?
    alert('speech API not supported in your browser')
    return

  for i in [seconds..1]
    utterance = new SpeechSynthesisUtterance("#{i}")
    speechSynthesis.speak(utterance)
    await sleep(1000)  # wait one second
  alert "done!"
