a: """
   basic heredoc
   on two lines
   """

print(a is "basic heredoc\non two lines")


a: '''
   a
     "b
   c
   '''

print(a is "a\n  \"b\nc")


a: '''one-liner'''

print(a is 'one-liner')


a: """
      out
      here
"""

print(a is "out\nhere")