a: """
   basic heredoc
   on two lines
   """

puts a is "basic heredoc\non two lines"


a: '''
   a
     "b
   c
   '''

puts a is "a\n  \"b\nc"


a: '''one-liner'''

puts a is 'one-liner'


a: """
      out
      here
"""

puts a is "out\nhere"


a: '''
      a
    b
  c
   '''

puts a is "    a\n  b\nc"

a: '''
a


b c
'''

puts a is "a\n\n\nb c"
