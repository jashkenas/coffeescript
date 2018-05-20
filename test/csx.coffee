# We usually do not check the actual JS output from the compiler, but since
# JSX is not natively supported by Node, we do it in this case.

test 'self closing', ->
  eqJS '''
    <div />
  ''', '''
    <div />;
  '''

test 'self closing formatting', ->
  eqJS '''
    <div/>
  ''', '''
    <div />;
  '''

test 'self closing multiline', ->
  eqJS '''
    <div
    />
  ''', '''
    <div />;
  '''

test 'regex attribute', ->
  eqJS '''
    <div x={/>asds/} />
  ''', '''
    <div x={/>asds/} />;
  '''

test 'string attribute', ->
  eqJS '''
    <div x="a" />
  ''', '''
    <div x="a" />;
  '''

test 'simple attribute', ->
  eqJS '''
    <div x={42} />
  ''', '''
    <div x={42} />;
  '''

test 'assignment attribute', ->
  eqJS '''
    <div x={y = 42} />
  ''', '''
    var y;

    <div x={y = 42} />;
  '''

test 'object attribute', ->
  eqJS '''
    <div x={{y: 42}} />
  ''', '''
    <div x={{
        y: 42
      }} />;
  '''

test 'attribute without value', ->
  eqJS '''
    <div checked x="hello" />
  ''', '''
    <div checked x="hello" />;
  '''

test 'paired', ->
  eqJS '''
    <div></div>
  ''', '''
    <div></div>;
  '''

test 'simple content', ->
  eqJS '''
    <div>Hello world</div>
  ''', '''
    <div>Hello world</div>;
  '''

test 'content interpolation', ->
  eqJS '''
    <div>Hello {42}</div>
  ''', '''
    <div>Hello {42}</div>;
  '''

test 'nested tag', ->
  eqJS '''
    <div><span /></div>
  ''', '''
    <div><span /></div>;
  '''

test 'tag inside interpolation formatting', ->
  eqJS '''
    <div>Hello {<span />}</div>
  ''', '''
    <div>Hello <span /></div>;
  '''

test 'tag inside interpolation, tags are callable', ->
  eqJS '''
    <div>Hello {<span /> x}</div>
  ''', '''
    <div>Hello {<span />(x)}</div>;
  '''

test 'tags inside interpolation, tags trigger implicit calls', ->
  eqJS '''
    <div>Hello {f <span />}</div>
  ''', '''
    <div>Hello {f(<span />)}</div>;
  '''

test 'regex in interpolation', ->
  eqJS '''
    <div x={/>asds/}><div />{/>asdsad</}</div>
  ''', '''
    <div x={/>asds/}><div />{/>asdsad</}</div>;
  '''

test 'interpolation in string attribute value', ->
  eqJS '''
    <div x="Hello #{world}" />
  ''', '''
    <div x={`Hello ${world}`} />;
  '''

# Unlike in `coffee-react-transform`.
test 'bare numbers not allowed', ->
  throws -> CoffeeScript.compile '<div x=3 />'

test 'bare expressions not allowed', ->
  throws -> CoffeeScript.compile '<div x=y />'

test 'bare complex expressions not allowed', ->
  throws -> CoffeeScript.compile '<div x=f(3) />'

test 'unescaped opening tag angle bracket disallowed', ->
  throws -> CoffeeScript.compile '<Person><<</Person>'

test 'space around equal sign', ->
  eqJS '''
    <div popular = "yes" />
  ''', '''
    <div popular="yes" />;
  '''

# The following tests were adopted from James Friend’s
# [https://github.com/jsdf/coffee-react-transform](https://github.com/jsdf/coffee-react-transform).

test 'ambiguous tag-like expression', ->
  throws -> CoffeeScript.compile 'x = a <b > c'

test 'ambiguous tag', ->
  eqJS '''
    a <b > c </b>
  ''', '''
    a(<b> c </b>);
  '''

test 'escaped CoffeeScript attribute', ->
  eqJS '''
    <Person name={if test() then 'yes' else 'no'} />
  ''', '''
    <Person name={test() ? 'yes' : 'no'} />;
  '''

test 'escaped CoffeeScript attribute over multiple lines', ->
  eqJS '''
    <Person name={
      if test()
        'yes'
      else
        'no'
    } />
  ''', '''
    <Person name={test() ? 'yes' : 'no'} />;
  '''

test 'multiple line escaped CoffeeScript with nested CSX', ->
  eqJS '''
    <Person name={
      if test()
        'yes'
      else
        'no'
    }>
    {

      for n in a
        <div> a
          asf
          <li xy={"as"}>{ n+1 }<a /> <a /> </li>
        </div>
    }

    </Person>
  ''', '''
    var n;

    <Person name={test() ? 'yes' : 'no'}>
    {(function() {
      var i, len, results;
      results = [];
      for (i = 0, len = a.length; i < len; i++) {
        n = a[i];
        results.push(<div> a
          asf
          <li xy={"as"}>{n + 1}<a /> <a /> </li>
        </div>);
      }
      return results;
    })()}

    </Person>;
  '''

test 'nested CSX within an attribute, with object attr value', ->
  eqJS '''
    <Company>
      <Person name={<NameComponent attr3={ {'a': {}, b: '{'} } />} />
    </Company>
  ''', '''
    <Company>
      <Person name={<NameComponent attr3={{
          'a': {},
          b: '{'
        }} />} />
    </Company>;
  '''

test 'complex nesting', ->
  eqJS '''
    <div code={someFunc({a:{b:{}, C:'}{}{'}})} />
  ''', '''
    <div code={someFunc({
        a: {
          b: {},
          C: '}{}{'
        }
      })} />;
  '''

test 'multiline tag with nested CSX within an attribute', ->
  eqJS '''
    <Person
      name={
        name = formatName(user.name)
        <NameComponent name={name.toUppercase()} />
      }
    >
      blah blah blah
    </Person>
  ''', '''
    var name;

    <Person name={name = formatName(user.name), <NameComponent name={name.toUppercase()} />}>
      blah blah blah
    </Person>;
  '''

test 'escaped CoffeeScript with nested object literals', ->
  eqJS '''
    <Person>
      blah blah blah {
        {'a' : {}, 'asd': 'asd'}
      }
    </Person>
  ''', '''
    <Person>
      blah blah blah {{
      'a': {},
      'asd': 'asd'
    }}
    </Person>;
  '''

test 'multiline tag attributes with escaped CoffeeScript', ->
  eqJS '''
    <Person name={if isActive() then 'active' else 'inactive'}
    someattr='on new line' />
  ''', '''
    <Person name={isActive() ? 'active' : 'inactive'} someattr='on new line' />;
  '''

test 'lots of attributes', ->
  eqJS '''
    <Person eyes={2} friends={getFriends()} popular = "yes"
    active={ if isActive() then 'active' else 'inactive' } data-attr='works' checked check={me_out}
    />
  ''', '''
    <Person eyes={2} friends={getFriends()} popular="yes" active={isActive() ? 'active' : 'inactive'} data-attr='works' checked check={me_out} />;
  '''

# TODO: fix partially indented CSX
# test 'multiline elements', ->
#   eqJS '''
#     <div something={
#       do ->
#         test = /432/gm # this is a regex
#         6 /432/gm # this is division
#     }
#     >
#     <div>
#     <div>
#     <div>
#       <article name={ new Date() } number={203}
#        range={getRange()}
#       >
#       </article>
#     </div>
#     </div>
#     </div>
#     </div>
#   ''', '''
#     bla
#   '''

test 'complex regex', ->
  eqJS '''
    <Person />
    /\\/\\/<Person \\/>\\>\\//
  ''', '''
    <Person />;

    /\\/\\/<Person \\/>\\>\\//;
  '''

test 'heregex', ->
  eqJS '''
    test = /432/gm # this is a regex
    6 /432/gm # this is division
    <Tag>
    {test = /<Tag>/} this is a regex containing something which looks like a tag
    </Tag>
    <Person />
    REGEX = /// ^
      (/ (?! [\s=] )   # comment comment <comment>comment</comment>
      [^ [ / \n \\ ]*  # comment comment
      (?:
        <Tag />
        (?: \\[\s\S]   # comment comment
          | \[         # comment comment
               [^ \] \n \\ ]*
               (?: \\[\s\S] [^ \] \n \\ ]* )*
               <Tag>tag</Tag>
             ]
        ) [^ [ / \n \\ ]*
      )*
      /) ([imgy]{0,4}) (?!\w)
    ///
    <Person />
  ''', '''
    var REGEX, test;

    test = /432/gm; // this is a regex

    6 / 432 / gm; // this is division

    <Tag>
    {(test = /<Tag>/)} this is a regex containing something which looks like a tag
    </Tag>;

    <Person />;

    REGEX = /^(\\/(?![s=])[^[\\/ ]*(?:<Tag\\/>(?:\\[sS]|[[^] ]*(?:\\[sS][^] ]*)*<Tag>tag<\\/Tag>])[^[\\/ ]*)*\\/)([imgy]{0,4})(?!w)/; // comment comment <comment>comment</comment>
    // comment comment
    // comment comment
    // comment comment

    <Person />;
  '''

test 'comment within CSX is not treated as comment', ->
  eqJS '''
    <Person>
    # i am not a comment
    </Person>
  ''', '''
    <Person>
    # i am not a comment
    </Person>;
  '''

test 'comment at start of CSX escape', ->
  eqJS '''
    <Person>
    {# i am a comment
      "i am a string"
    }
    </Person>
  ''', '''
    <Person>
    {// i am a comment
    "i am a string"}
    </Person>;
  '''

test 'comment at end of CSX escape', ->
  eqJS '''
    <Person>
    {"i am a string"
    # i am a comment
    }
    </Person>
  ''', '''
    <Person>
    {"i am a string"
    // i am a comment
    }
    </Person>;
  '''

test 'CSX comment cannot be used inside interpolation', ->
  throws -> CoffeeScript.compile '''
    <Person>
    {# i am a comment}
    </Person>
  '''

test 'comment syntax cannot be used inline', ->
  throws -> CoffeeScript.compile '''
    <Person>{#comment inline}</Person>
  '''

test 'string within CSX is ignored', ->
  eqJS '''
    <Person> "i am not a string" 'nor am i' </Person>
  ''', '''
    <Person> "i am not a string" 'nor am i' </Person>;
  '''

test 'special chars within CSX are ignored', ->
  eqJS """
    <Person> a,/';][' a\''@$%^&˚¬∑˜˚∆å∂¬˚*()*&^%$>> '"''"'''\'\'m' i </Person>
  """, """
    <Person> a,/';][' a''@$%^&˚¬∑˜˚∆å∂¬˚*()*&^%$>> '"''"'''''m' i </Person>;
  """

test 'html entities (name, decimal, hex) within CSX', ->
  eqJS '''
    <Person>  &&&&euro;  &#8364; &#x20AC;;; </Person>
  ''', '''
    <Person>  &&&&euro;  &#8364; &#x20AC;;; </Person>;
  '''

test 'tag with {{}}', ->
  eqJS '''
    <Person name={{value: item, key, item}} />
  ''', '''
    <Person name={{
        value: item,
        key,
        item
      }} />;
  '''

test 'tag with namespace', ->
  eqJS '''
    <Something.Tag></Something.Tag>
  ''', '''
    <Something.Tag></Something.Tag>;
  '''

test 'tag with lowercase namespace', ->
  eqJS '''
    <something.tag></something.tag>
  ''', '''
    <something.tag></something.tag>;
  '''

test 'self closing tag with namespace', ->
  eqJS '''
    <Something.Tag />
  ''', '''
    <Something.Tag />;
  '''

test 'self closing tag with spread attribute', ->
  eqJS '''
    <Component a={b} {x...} b="c" />
  ''', '''
    <Component a={b} {...x} b="c" />;
  '''

test 'complex spread attribute', ->
  eqJS '''
    <Component {x...} a={b} {x...} b="c" {$my_xtraCoolVar123...} />
  ''', '''
    <Component {...x} a={b} {...x} b="c" {...$my_xtraCoolVar123} />;
  '''

test 'multiline spread attribute', ->
  eqJS '''
    <Component {
      x...} a={b} {x...} b="c" {z...}>
    </Component>
  ''', '''
    <Component {...x} a={b} {...x} b="c" {...z}>
    </Component>;
  '''

test 'multiline tag with spread attribute', ->
  eqJS '''
    <Component
      z="1"
      {x...}
      a={b}
      b="c"
    >
    </Component>
  ''', '''
    <Component z="1" {...x} a={b} b="c">
    </Component>;
  '''

test 'multiline tag with spread attribute first', ->
  eqJS '''
    <Component
      {x...}
      z="1"
      a={b}
      b="c"
    >
    </Component>
  ''', '''
    <Component {...x} z="1" a={b} b="c">
    </Component>;
  '''

test 'complex multiline spread attribute', ->
  eqJS '''
    <Component
      {y...
      } a={b} {x...} b="c" {z...}>
      <div code={someFunc({a:{b:{}, C:'}'}})} />
    </Component>
  ''', '''
    <Component {...y} a={b} {...x} b="c" {...z}>
      <div code={someFunc({
        a: {
          b: {},
          C: '}'
        }
      })} />
    </Component>;
  '''

test 'self closing spread attribute on single line', ->
  eqJS '''
    <Component a="b" c="d" {@props...} />
  ''', '''
    <Component a="b" c="d" {...this.props} />;
  '''

test 'self closing spread attribute on new line', ->
  eqJS '''
    <Component
      a="b"
      c="d"
      {@props...}
    />
  ''', '''
    <Component a="b" c="d" {...this.props} />;
  '''

test 'self closing spread attribute on same line', ->
  eqJS '''
    <Component
      a="b"
      c="d"
      {@props...} />
  ''', '''
    <Component a="b" c="d" {...this.props} />;
  '''

test 'self closing spread attribute on next line', ->
  eqJS '''
    <Component
      a="b"
      c="d"
      {@props...}

    />
  ''', '''
    <Component a="b" c="d" {...this.props} />;
  '''

test 'empty strings are not converted to true', ->
  eqJS '''
    <Component val="" />
  ''', '''
    <Component val="" />;
  '''

test 'CoffeeScript @ syntax in tag name', ->
  throws -> CoffeeScript.compile '''
    <@Component>
      <Component />
    </@Component>
  '''

test 'hyphens in tag names', ->
  eqJS '''
    <paper-button className="button">{text}</paper-button>
  ''', '''
    <paper-button className="button">{text}</paper-button>;
  '''

test 'closing tags must be closed', ->
  throws -> CoffeeScript.compile '''
    <a></a
  '''

# Tests for allowing less than operator without spaces when ther is no CSX

test 'unspaced less than without CSX: identifier', ->
  a = 3
  div = 5
  ok a<div

test 'unspaced less than without CSX: number', ->
  div = 5
  ok 3<div

test 'unspaced less than without CSX: paren', ->
  div = 5
  ok (3)<div

test 'unspaced less than without CSX: index', ->
  div = 5
  a = [3]
  ok a[0]<div

test 'tag inside CSX works following: identifier', ->
  eqJS '''
    <span>a<div /></span>
  ''', '''
    <span>a<div /></span>;
  '''

test 'tag inside CSX works following: number', ->
  eqJS '''
    <span>3<div /></span>
  ''', '''
    <span>3<div /></span>;
  '''

test 'tag inside CSX works following: paren', ->
  eqJS '''
    <span>(3)<div /></span>
  ''', '''
    <span>(3)<div /></span>;
  '''

test 'tag inside CSX works following: square bracket', ->
  eqJS '''
    <span>]<div /></span>
  ''', '''
    <span>]<div /></span>;
  '''

test 'unspaced less than inside CSX works but is not encouraged', ->
  eqJS '''
      a = 3
      div = 5
      html = <span>{a<div}</span>
    ''', '''
      var a, div, html;

      a = 3;

      div = 5;

      html = <span>{a < div}</span>;
    '''

test 'unspaced less than before CSX works but is not encouraged', ->
  eqJS '''
      div = 5
      res = 2<div
      html = <span />
    ''', '''
      var div, html, res;

      div = 5;

      res = 2 < div;

      html = <span />;
    '''

test 'unspaced less than after CSX works but is not encouraged', ->
  eqJS '''
      div = 5
      html = <span />
      res = 2<div
    ''', '''
      var div, html, res;

      div = 5;

      html = <span />;

      res = 2 < div;
    '''

test '#4686: comments inside interpolations that also contain CSX tags', ->
  eqJS '''
    <div>
      {
        # comment
        <div />
      }
    </div>
  ''', '''
    <div>
      {  // comment
    <div />}
    </div>;
  '''

test '#4686: comments inside interpolations that also contain CSX attributes', ->
  eqJS '''
    <div>
      <div anAttr={
        # comment
        "value"
      } />
    </div>
  ''', '''
    <div>
      {  // comment
    <div anAttr={"value"} />}
    </div>;
  '''

# https://reactjs.org/blog/2017/11/28/react-v16.2.0-fragment-support.html
test 'JSX fragments: empty fragment', ->
  eqJS '''
    <></>
  ''', '''
    <></>;
  '''

test 'JSX fragments: fragment with text nodes', ->
  eqJS '''
    <>
      Some text.
      <h2>A heading</h2>
      More text.
      <h2>Another heading</h2>
      Even more text.
    </>
  ''', '''
    <>
      Some text.
      <h2>A heading</h2>
      More text.
      <h2>Another heading</h2>
      Even more text.
    </>;
  '''

test 'JSX fragments: fragment with component nodes', ->
  eqJS '''
    Component = (props) =>
      <Fragment>
        <OtherComponent />
        <OtherComponent />
      </Fragment>
  ''', '''
    var Component;

    Component = (props) => {
      return <Fragment>
        <OtherComponent />
        <OtherComponent />
      </Fragment>;
    };
  '''

test '#5055: JSX expression indentation bug', ->
  eqJS '''
    <div>
      {someCondition &&
        <span />
      }
    </div>
  ''', '''
    <div>
      {someCondition && <span />}
    </div>;
  '''

  eqJS '''
    <div>{someString +
         "abc"
      }
    </div>
  ''', '''
    <div>{someString + "abc"}
    </div>;
  '''

  eqJS '''
    <div>
      {a ?
      <span />
      }
    </div>
  ''', '''
    <div>
      {typeof a !== "undefined" && a !== null ? a : <span />}
    </div>;
  '''

# JSX is like XML, in that there needs to be a root element; but
# technically, adjacent top-level elements where only the last one
# is returned (as opposed to a fragment or root element) is permissible
# syntax. It’s almost certainly an error, but it’s valid, so need to leave it
# to linters to catch. https://github.com/jashkenas/coffeescript/pull/5049
test '“Adjacent” tags on separate lines should still compile', ->
  eqJS '''
    ->
      <a />
      <b />
  ''', '''
    (function() {
      <a />;
      return <b />;
    });
  '''
