a: """
   basic heredoc
   on two lines
   """

ok a is "basic heredoc\non two lines"


a: '''
   a
     "b
   c
   '''

ok a is "a\n  \"b\nc"


a: '''one-liner'''

ok a is 'one-liner'


a: """
      out
      here
"""

ok a is "out\nhere"


a: '''
      a
    b
  c
   '''

ok a is "    a\n  b\nc"


a: '''
a


b c
'''

ok a is "a\n\n\nb c"


a: '''more"than"one"quote'''

ok a is 'more"than"one"quote'