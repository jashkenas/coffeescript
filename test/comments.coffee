##############
## Comments ##
##############
# note: some tests purposely left in outermost scope
# note: awkward spacing seen in some tests is likely intentional

# comments in objects
obj1 = {
# comment
  # comment
    # comment
  one: 1
# comment
  two: 2
    # comment
}

ok Object::hasOwnProperty.call(obj1,'one')
eq obj1.one, 1
ok Object::hasOwnProperty.call(obj1,'two')
eq obj1.two, 2

# comments in YAML-style objects
obj2 =
# comment
  # comment
    # comment
  three: 3
# comment
  four: 4
    # comment

ok Object::hasOwnProperty.call(obj2,'three')
eq obj2.three, 3
ok Object::hasOwnProperty.call(obj2,'four')
eq obj2.four, 4

# comments following operators that continue lines
(->
  sum =
    1 +
    1 + # comment
    1
  eq 3, sum
)()

# comments in functions
fn = ->
# comment
  false
  false   # comment
  false
  # comment

# comment
  true

ok fn()

fn2 = -> #comment
  fn()
  # comment

ok fn2()

# trailing comment before an outdent
nonce = {}
fn3 = ->
  if true
    undefined # comment
  nonce

eq nonce, fn3()

# comments in a switch
nonce = {}
result = switch nonce #comment
  # comment
  when false then undefined
  # comment
  when null #comment
    undefined
  else nonce # comment

eq nonce, result

# comment with conditional statements
(->
  nonce = {}
  result = if false # comment
    undefined
  #comment
  else # comment
    nonce
    # comment
  eq nonce, result
)()

# spaced comments with conditional statements
nonce = {}
result = if false
  undefined

# comment
else if false
  undefined

# comment
else
  nonce

eq nonce, result


#### Block Comments

###
  This is a here-comment.
  Kind of like a heredoc.
###
#
obj = {
  a: 'b'
  ###
  comment
  ###
  c: 'd'
}

# block comments in functions
(->
  nonce = {}

  fn1 = ->
    true
    ###
    false
    ###

  ok fn1()

  fn2 =  ->
    ###
    block comment
    ###
    nonce

  eq nonce, fn2()

  fn3 = ->
    nonce
  ###
  block comment
  ###

  eq nonce, fn3()

  fn4 = ->
    one = ->
      ###
        block comment
      ###
      two = ->
        three = ->
          nonce

  eq nonce, fn4()()()()
)()

# block comments inside class bodies
(->
  class A
    a: ->

    ###
    Comment
    ###
    b: ->

  ok A.prototype.b instanceof Function

  class B
    ###
    Comment
    ###
    a: ->
    b: ->

  ok B.prototype.a instanceof Function
)()
