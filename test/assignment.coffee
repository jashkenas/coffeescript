################
## Assignment ##
################


# context property assignment (using @)
(->
  nonce = {}
  addMethod = ->
    @method = -> nonce
    this
  eq nonce, addMethod.call({}).method()
)()

# unassignable values
(->
  nonce = {}
  for nonref in ['', '""', '0', 'f()'].concat CoffeeScript.RESERVED
    eq nonce, (try CoffeeScript.compile "#{nonref} = v" catch e then nonce)
)()

# compound assignments should not declare
# TODO: make description more clear
# TODO: remove reference to Math
eq Math, (-> Math or= 0)()


#### Statements as Expressions

# assign the result of a try/catch block
(->
  # multiline
  result = try
    nonexistent * missing
  catch error
    true
  eq true, result

  # single line
  result = try nonexistent * missing catch error then true
  eq true, result
)()

# conditionals
(->
  # assign inside the condition of a conditional statement
  nonce = {}
  if a = nonce then 1
  eq nonce, a
  1 if b = nonce
  eq nonce, b

  # assign the result of a conditional statement
  c = if true then nonce
  eq nonce, c
)()

# assign inside the condition of a `while` loop
(->
  nonce = {}
  count = 1
  a = nonce while count--
  eq nonce, a
  count = 1
  while count--
    b = nonce
  eq nonce, b
)()


#### Compound Assignment

# compound assignment (math operators)
(->
  num = 10
  num -= 5
  eq 5, num

  num *= 10
  eq 50, num

  num /= 10
  eq 5, num

  num %= 3
  eq 2, num
)()

# more compound assignment
(->
  a = {}
  val = undefined
  val ||= a
  val ||= true
  eq a, val

  b = {}
  val &&= true
  eq val, true
  val &&= b
  eq b, val

  c = {}
  val = null
  val ?= c
  val ?= true
  eq c, val
)()


#### Destructuring Assignment

# NO TESTS?!
# TODO: make tests for destructuring assignment
