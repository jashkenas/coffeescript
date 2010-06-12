countdown: num for num in [10..1]

eggDelivery: ->
  for i in [0...eggs.length] by 12
    dozenEggs: eggs[i...i+12]
    deliver new eggCarton(dozen)
