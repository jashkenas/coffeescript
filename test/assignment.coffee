#############
## Assignment
#############

# context property assignment (using @)
(->
  nonce = {}
  addMethod = ->
    @method = -> nonce
    this
  eq addMethod.call({}).method(), nonce
)()

# unassignable values
(->
  nonce = {}
  for nonref in ['', '""', '0', 'f()'].concat CoffeeScript.RESERVED
    eq nonce, (try CoffeeScript.compile "#{nonref} = v" catch e then nonce)
)()

# compound assignments should not declare
# TODO: make description more clear
eq Math, (-> Math or= 0)()


#### Statements as Expressions

# assign the result of a try/catch block
(->
  # multiline
  result = try
    nonexistent * missing
  catch error
    true
  eq result, true

  # single line
  result = try nonexistent * missing catch error then true
  eq result, true
)()

# conditionals
(->
  # assign inside the condition of a conditional statement
  nonce = {}
  if a = nonce then 1
  eq a, nonce
  1 if b = nonce
  eq b, nonce

  # assign the result of a conditional statement
  c = if true then nonce
  eq c, nonce
)()

# assign inside the condition of a `while` loop
(->
  nonce = {}
  count = 1
  a = nonce while count--
  eq a, nonce
  count = 1
  while count--
    b = nonce
  eq b, nonce
)()


#### Compound Assignment

# compound assignment (math operators)
(->
  num = 10
  num -= 5
  eq num, 5

  num *= 10
  eq num, 50

  num /= 10
  eq num, 5

  num %= 3
  eq num, 2
)()

# more compound assignment
(->
  a = {}
  val = undefined
  val ||= a
  val ||= true
  eq val, a

  b = {}
  val &&= true
  eq val, true
  val &&= b
  eq val, b

  c = {}
  val = null
  val ?= c
  val ?= true
  eq val, c
)()


#### Destructuring Assignment

# NO TESTS?!
