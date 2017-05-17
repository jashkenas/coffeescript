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

test 'self-closing tags', ->
  input = '''
    <h1/>
    <h2 />
    <h3 a='b' c={d}/>
    <h4
        e='f g'
    />
  '''
  output = '''
	<h1></h1>;

	<h2></h2>;

	<h3 a='b' c={d}></h3>;

	<h4 e='f g'></h4>;
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

test 'element enders', ->
  input = '''
    x %h1, 2
    %h2 {
      if a
        %a
      else
        %b }
    [%a, %b]
    f(%h1( a={b} ))
    z = (%b{ x } for x in y)
    y =
      %b if c
    x = ->
      %b unless c
  '''
  output = '''
    var FORCE_EXPRESSION, x, y, z;

    x(<h1></h1>, 2);

    <h2>{FORCE_EXPRESSION = (a ? <a></a> : <b></b>)}</h2>;

    [<a></a>, <b></b>];

    f(<h1 a={b}></h1>);

    z = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = y.length; i < len; i++) {
        x = y[i];
        results.push(<b x={x}></b>);
      }
      return results;
    })();

    y = c ? <b></b> : void 0;

    x = function() {
      if (!c) {
        return <b></b>;
      }
    };
  '''
  eq toJS(input), output

test 'shorthand tags', ->
  input = '''
    %h1#abc
      #def.ghi.jkl
  '''
  output = '''<h1 id='abc'><div id='def' className='ghi jkl'></div></h1>;'''
  eq toJS(input), output

test 'multiline attributes', ->
  input = '''
    %h1(
      a={b}
      c='d' )
      %a( e={f g}
          h='i' )
        %b( j = 'k' 
          l='m'
          )
        %b( n = 'o' 
          p='q'
        )
  '''
  output = '''
    <h1 a={b} c='d'><a e={f(g)} h='i'><b j='k' l='m'></b> <b n='o' p='q'></b></a></h1>;
  '''
  eq toJS(input), output

test 'multiline attributes in tags', ->
  input = '''
    <h1
      a={b}
      c='d'>
      <a e={f g}
         h='i' >
        <b j = 'k' 
          l='m'
          />
        <b n = 'o' 
          p='q'
        ></b>
      </a></h1>
  '''
  output = '''
    <h1 a={b} c='d'><a e={f(g)} h='i'><b j='k' l='m'></b> <b n='o' p='q'></b></a></h1>;
  '''
  eq toJS(input), output

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
  output = '''
    var Recipe;

    Recipe = function(arg) {
      var FORCE_EXPRESSION, i, ingredients, name, steps;
      name = arg.name, ingredients = arg.ingredients, steps = arg.steps;
      return <section id={name.toLowerCase().replace(/ /g, '-')}><h1>{name}</h1> <ul className='ingredients'>{FORCE_EXPRESSION = (function() {
        var j, len, results;
        results = [];
        for (i = j = 0, len = ingredients.length; j < len; i = ++j) {
          name = ingredients[i].name;
          results.push(<li key={i}>{ingredient.name}</li>);
        }
        return results;
      })()}</ul> <section className='instructions'><h2>Cooking Instructions</h2> {steps.map(function(step, i) {
        return <p key={i}>{step}</p>;
      })}</section></section>;
    };
  '''
  eq toJS(input), output

# TODO:
# error tests:
# - no whitespace before element body
# - outdented end tag, expression }, ...
# - mismatched start/end tag
