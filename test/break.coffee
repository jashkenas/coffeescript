########
## Break
########

# break at the top level
(->
  for i in [1,2,3]
    result = i
    if i == 2
      break
  eq result, 2
)()

# break *not* at the top level
(->
  someFunc = () ->
    i = 0
    while ++i < 3
      result = i
      break if i > 1
    result
  eq someFunc(), 2
)()
