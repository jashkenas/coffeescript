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

test 'inline element, no body', ->
  input = '%h1'
  output = '<h1></h1>;'
  eq toJS(input), output

test 'inline element with parenthesized attributes', ->
  input = '''%h1( a="b" c='def' g={h + i})'''
  output = '''<h1 a="b" c='def' g={h + i}></h1>;'''
  eq toJS(input), output

test 'inline element with parenthesized attributes and content', ->
  input = '''%h1( a="b" c='def' g={h + i}) jkl'''
  output = '''<h1 a="b" c='def' g={h + i}>jkl</h1>;'''
  eq toJS(input), output

test 'inline =expressionBody', ->
  input = '%h1= name'
  output = '<h1>{name}</h1>;'
  eq toJS(input), output

test 'expression inline content', ->
  input = '%h1 {@abc}'
  output = '<h1>{this.abc}</h1>;'
  eq toJS(input), output

test 'mixed inline content', ->
  input = '%h1 name {@abc}'
  output = '<h1>name {this.abc}</h1>;'
  eq toJS(input), output

test 'mixed inline content normalize whitespace', ->
  input = '%h1 name  {@abc}'
  output = '<h1>name {this.abc}</h1>;'
  eq toJS(input), output

test 'mixed inline content normalize trailing whitespace', ->
  input = '%h1 name  {@abc} '
  output = '<h1>name {this.abc}</h1>;'
  eq toJS(input), output

test 'all together now', ->
  input = '''
    Recipe = ({name, ingredients, steps}) ->
      %section( id={ name.toLowerCase().replace / /g, '-' })
        %h1= name
        %ul.ingredients
          = for {name}, i in ingredients
            %li{ key: i } {ingredient.name}
        %section.instructions
          %h2 Cooking Instructions
          {steps.map (step, i) ->
            %p( key={i} )= step
          }
  '''
  output = ''
  eq toJS(input), output

# object spread attributes
# no-value (true) attributes
