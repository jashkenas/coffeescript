countdown = num for num in [10..1]

deliverEggs = ->
  for i in [0...eggs.length] by 12
    dozen = eggs[i...i+12]
    deliver new eggCarton dozen
