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

test 'indented equals expression', ->
  input = '''
    %h1
      = abc
  '''
  output = '<h1>{abc}</h1>;'
  eq toJS(input), output

test 'no equals expression unless line-starting', ->
  input = '''
    %h1
      x = abc
      y= abc
      {z}= abc
      {w} = abc
      =abc
  '''
  # output = '<h1>x = abc y= abc {z}= abc {w} = abc {abc}</h1>;' TODO: once whitespace (or lack thereof) between children is fixed use this one
  output = '<h1>x = abc y= abc {z} = abc {w} = abc {abc}</h1>;'
  eq toJS(input), output

test 'equals for loop', ->
  input = '''
    %h1
      = for x in ['a', 'b', 'c']
        %b= x
  '''
  output = '''
    var FORCE_EXPRESSION, x;

    <h1>{FORCE_EXPRESSION = (function() {
      var i, len, ref, results;
      ref = ['a', 'b', 'c'];
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        x = ref[i];
        results.push(<b>{x}</b>);
      }
      return results;
    })()}</h1>;
  '''
  eq toJS(input), output

test 'various indented expressions', ->
  input = '''
    %h1
      {@x} {@y}
      abc
      {@z}
      def {@g + h}
      {@i +
        @j }
      {
        @k
      }
      { @l
      }
      {
        @m }
  '''
  output = '<h1>{this.x} {this.y} abc {this.z} def {this.g + h} {this.i + this.j} {this.k} {this.l} {this.m}</h1>;'
  eq toJS(input), output

test 'simple object attributes', ->
  input = '''
    %h1{ a: b }
  '''
  output = '<h1 a={b}></h1>;'
  eq toJS(input), output

test 'value object attributes', ->
  input = '''
    %h1{ a, @b, c: d() }
  '''
  output = '<h1 a={a} b={this.b} c={d()}></h1>;'
  eq toJS(input), output

test 'multi-line object attributes', ->
  input = '''
    x = ->
      %h1{
        a
        @b
        c: d()
      }
    y
  '''
  output = '''
	var x;

	x = function() {
	  return <h1 a={a} b={this.b} c={d()}></h1>;
	};

	y;
  '''
  eq toJS(input), output

test 'parenthesized and object attributes', ->
  input = '''
    %h1{ a, @b, c: d() }( e = 'f' )
    %h2(e={f}){a,@b,c:d()}
  '''
  output = '''
    <h1 e='f' a={a} b={this.b} c={d()}></h1>;

    <h2 e={f} a={a} b={this.b} c={d()}></h2>;
  '''
  eq toJS(input), output

test 'simple tag', ->
  input = '''
    <h1></h1>
  '''
  output = '''
    <h1></h1>;
  '''
  eq toJS(input), output

test 'tag with attributes and indented body', ->
  input = '''
    <h1 a="b" c={@d}>
      <b>
        Hey
        = @name
      </b>
    </h1>
  '''
  output = '''
    <h1 a="b" c={this.d}><b>Hey {this.name}</b></h1>;
  '''
  eq toJS(input), output

test 'nested inline tags', ->
  input = '''
    <h1   a="b" c = {@d} ><b > Hey {@name}</b></h1>
  '''
  output = '''
    <h1 a="b" c={this.d}><b>Hey {this.name}</b></h1>;
  '''
  eq toJS(input), output

# test '#id tags', ->
#   input = '''
#     %h1#abc
#       #def
#   '''
#   output = '<h1 id="abc"><div id="def"></div></h1>;'
#   eq toJS(input), output

test 'all together now', ->
  input = '''
    Recipe = ({name, ingredients, steps}) ->
      %section( id={ name.toLowerCase().replace(/ /g, '-')})
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

# error tests:
# - no whitespace before element body
# - outdented end tag, expression }, ...
# - mismatched start/end tag
# object spread attributes
# no-value (true) attributes
