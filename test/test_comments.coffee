  # comment
func: ->
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
    something_else()

->
  code()
  # comment

ok func()

func
func
# Line3

obj: {
# comment
  # comment
    # comment
  one: 1
# comment
  two: 2
    # comment
}

result: if true # comment
  false

ok not result

result: if false
  false
else # comment
  45

ok result is 45


test:
  'test ' +
  'test ' + # comment
  'test'

ok test is 'test test test'

###
  This is a here-comment.
  Kind of like a heredoc.
###

func: ->
  ###
  Another block comment.
  ###
  code