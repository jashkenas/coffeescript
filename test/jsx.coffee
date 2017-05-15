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
