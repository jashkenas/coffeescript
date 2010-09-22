# comment before a ...

###
... block comment.
###


  # comment
func = ->
# comment
  false
  false   # comment
  false

# comment
  true

switch 'string'
  # comment
  when false then something()
  # comment
  when null
    somethingElse()

->
  code()
  # comment

ok func()

func
func
# Line3

obj = {
# comment
  # comment
    # comment
  one: 1
# comment
  two: 2
    # comment
}

result = if true # comment
  false

ok not result

result = if false
  false
else # comment
  45

ok result is 45


test =
  'test ' +
  'test ' + # comment
  'test'

ok test is 'test test test'

###
  This is a here-comment.
  Kind of like a heredoc.
###

func = ->
  ###
  Another block comment.
  ###
  code

func = ->
  one = ->
    two = ->
      three = ->
  ###
  block.
  ###
  four = ->

fn1 = ->
  oneLevel = null
###
This isn't fine.
###

ok ok

obj = {
  a: 'b'
  ###
  comment
  ###
  c: 'd'
}

arr = [
  1, 2, 3,
  ###
  four
  ###
  5, 6, 7
]

# Spaced comments in if / elses.
result = if false
  1

# comment
else if false
  2

# comment
else
  3

ok result is 3


result = switch 'z'
  when 'z' then 7
# comment
ok result is 7


# Trailing-line comment before an outdent.
func = ->
  if true
    true # comment
  7

ok func() is 7


# Trailing herecomment in a function.
fn = ->
  code
  ###
  debug code commented
  ###

fn2 = ->


class A
  b: ->

  ###
  Comment
  ###
  c: ->

ok A.prototype.c instanceof Function

class A
  ###
  Comment
  ###
  b: ->
  c: ->

ok A.prototype.b instanceof Function
