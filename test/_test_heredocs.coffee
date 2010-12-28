a = """
    basic heredoc
    on two lines
    """

ok a is "basic heredoc\non two lines"


a = '''
    a
      "b
    c
    '''

ok a is "a\n  \"b\nc"


a = """
a
 b
  c
"""

ok a is "a\n b\n  c"


a = '''one-liner'''

ok a is 'one-liner'


a = """
      out
      here
"""

ok a is "out\nhere"


a = '''
       a
     b
   c
    '''

ok a is "    a\n  b\nc"


a = '''
a


b c
'''

ok a is "a\n\n\nb c"


a = '''more"than"one"quote'''

ok a is 'more"than"one"quote'


val = 10

a = """
    basic heredoc #{val}
    on two lines
    """

b = '''
    basic heredoc #{val}
    on two lines
    '''

ok a is "basic heredoc 10\non two lines"
ok b is "basic heredoc \#{val}\non two lines"


a = '''here's an apostrophe'''
ok a is "here's an apostrophe"


# The indentation detector ignores blank lines without trailing whitespace
a = """
    one
    two

    """
ok a is "one\ntwo\n"

eq ''' line 0
  should not be relevant
    to the indent level
''', '
 line 0\n
should not be relevant\n
  to the indent level
'

eq ''' '\\\' ''', " '\\' "
eq """ "\\\" """, ' "\\" '

eq '''  <- keep these spaces ->  ''', '  <- keep these spaces ->  '

eq 'multiline nested "interpolations" work', """multiline #{
  "nested #{(->
    ok yes
    "\"interpolations\""
  )()}"
} work"""
