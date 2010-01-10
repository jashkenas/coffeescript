countdown: num for num in [10..1]

egg_delivery: =>
  for i in [0...eggs.length] by 12
    dozen_eggs: eggs[i...i+12]
    deliver(new egg_carton(dozen))
