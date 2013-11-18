# String Literals
# ---------------

# TODO: refactor string literal tests
# TODO: add indexing and method invocation tests: "string"["toString"] is String::toString, "string".toString() is "string"

# * Strings
# * Heredocs

test "backslash escapes", ->
  eq "\\/\\\\", /\/\\/.source

eq '(((dollars)))', '\(\(\(dollars\)\)\)'
eq 'one two three', "one
 two
 three"
eq "four five", 'four

 five'

test "#3229, multine strings", ->
  eq 'one
      two', 'one two'
  eq "one
      two", 'one two'
  eq 'a \
      b\
      c  \
      d', 'a bc  d'
  eq "a \
      b\
      c  \
      d", 'a bc  d'
  eq 'one

        two', 'one two'
  eq "one

        two", 'one two'
  eq '
        a
        b
    ', 'a b'
  eq "
        a
        b
    ", 'a b'
  eq "interpolation #{1}
      follows #{2}  \
      too #{3}\
      !", 'interpolation 1 follows 2  too 3!'
  eq "a #{
    'string ' + "inside
                 interpolation"
    }", "a string inside interpolation"
  eq '
    indentation
      doesn\'t
  matter', 'indentation doesn\'t matter'

#647
eq "''Hello, World\\''", '''
'\'Hello, World\\\''
'''
eq '""Hello, World\\""', """
"\"Hello, World\\\""
"""
eq 'Hello, World\n', '''
Hello, World\

'''

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
''', ' line 0\nshould not be relevant\n  to the indent level'

eq ''' '\\\' ''', " '\\' "
eq """ "\\\" """, ' "\\" '

eq '''  <- keep these spaces ->  ''', '  <- keep these spaces ->  '


test "#1046, empty string interpolations", ->
  eq "#{ }", ''
