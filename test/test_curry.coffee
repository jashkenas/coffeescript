f: (x,y,z) ->
  x*y*z*((@num or 4) + 5)

obj: {num: 5}
g: f <- obj, (1,1)
h: f <- (1,2)
i: f <- obj

ok g(2) is 20
ok h(2) is 36
ok i(1,2,3) is 60