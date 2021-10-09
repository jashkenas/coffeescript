helloIter = ("Hello #{animal}!" for each animal in ['dog', 'cat', 'birb'])

messageToDog  = helloIter.next().value
messageToCat  = helloIter.next().value
messageToBirb = helloIter.next().value
