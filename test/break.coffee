###########
## Break ##
###########


# break at the top level
(->
  for i in [1,2,3]
    result = i
    if i == 2
      break
  eq 2, result
)()

# break *not* at the top level
(->
  someFunc = () ->
    i = 0
    while ++i < 3
      result = i
      break if i > 1
    result
  eq 2, someFunc()
)()
