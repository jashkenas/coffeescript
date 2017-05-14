# JSX-Haml
# --------

test 'simple inline element', ->
  # element = %h1 Hello, world!
  input = '%h1 Hello, world!'
  output = '<h1>Hello, world!</h1>;'
  eq toJS(input), output

test 'simple indented element', ->
  input = '''
    %h1
      Hello, world!
    '''
  output = '<h1>Hello, world!</h1>;'
  eq toJS(input), output

test 'simple nested element', ->
  input = '''
    %h1
      %a
        Hello, world!
    '''
  output = '<h1><a>Hello, world!</a></h1>;'
  eq toJS(input), output
