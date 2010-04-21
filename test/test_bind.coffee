helpers: require('../lib/helpers').helpers

f: (x,y,z) ->
  x * y * z * ((@num or 4) + 5)

obj: {num: 5}

func: f <- obj, 1, 1
ok func(2) is 20

func: f <- {}, 1, 2
ok func(2) is 36

func: f <- obj
ok func(1, 2, 3) is 60

in_first_ten: helpers.include <- null, [0...10]

ok in_first_ten 3
ok in_first_ten 9
ok not in_first_ten -1
ok not in_first_ten 12