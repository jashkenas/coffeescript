# We usually do not check the actual JS output from the compiler, but since
# CSX is not readily supported by Node, we do it in this case
eqCSX = (cs, js) ->
  eq CoffeeScript.compile(cs, {bare: true}), js + '\n'

test 'self closing', ->
  eqCSX '''
    <div />
  ''', '''
    <div />;
  '''

test 'self closing formatting', ->
  eqCSX '''
    <div/>
  ''', '''
    <div />;
  '''

test 'self closing multiline', ->
  eqCSX '''
    <div
    />
  ''', '''
    <div />;
  '''

test 'regex attribute', ->
  eqCSX '''
    <div x={/>asds/} />
  ''', '''
    <div x={/>asds/} />;
  '''

test 'string attribute', ->
  eqCSX '''
    <div x="a" />
  ''', '''
    <div x="a" />;
  '''

test 'simple attribute', ->
  eqCSX '''
    <div x={42} />
  ''', '''
    <div x={42} />;
  '''

test 'assignment attribute', ->
  eqCSX '''
    <div x={y = 42} />
  ''', '''
    var y;

    <div x={y = 42} />;
  '''

test 'object attribute', ->
  eqCSX '''
    <div x={{y: 42}} />
  ''', '''
    <div x={{
        y: 42
      }} />;
  '''

test 'paired', ->
  eqCSX '''
    <div></div>
  ''', '''
    <div></div>;
  '''

test 'simple content', ->
  eqCSX '''
    <div>Hello world</div>
  ''', '''
    <div>Hello world</div>;
  '''

test 'content interpolation', ->
  eqCSX '''
    <div>Hello {42}</div>
  ''', '''
    <div>Hello {42}</div>;
  '''

test 'nested tag', ->
  eqCSX '''
    <div><span /></div>
  ''', '''
    <div><span /></div>;
  '''

test 'tag inside interpolation formatting', ->
  eqCSX '''
    <div>Hello {<span />}</div>
  ''', '''
    <div>Hello <span /></div>;
  '''

test 'tag inside interpolation, tags are callable', ->
  eqCSX '''
    <div>Hello {<span /> x}</div>
  ''', '''
    <div>Hello {<span />(x)}</div>;
  '''

test 'tags inside interpolation, tags trigger implicit calls', ->
  eqCSX '''
    <div>Hello {f <span />}</div>
  ''', '''
    <div>Hello {f(<span />)}</div>;
  '''

test 'regex in interpolation', ->
  eqCSX '''
    <div x={/>asds/}><div />{/>asdsad</}</div>
  ''', '''
    <div x={/>asds/}><div />{/>asdsad</}</div>;
  '''

# Unlike in coffee-react-transform
test 'bare numbers not allowed', ->
  throws -> CoffeeScript.compile '<div x=3 />'

test 'bare expressions not allowed', ->
  throws -> CoffeeScript.compile '<div x=y />'

test 'bare complex expressions not allowed', ->
  throws -> CoffeeScript.compile '<div x=f(3) />'

test 'unescaped opening tag arrows disallowed', ->
  throws -> CoffeeScript.compile '<Person><<</Person>'

test 'space around equal sign', ->
  eqCSX '''
    <div popular = "yes" />
  ''', '''
    <div popular="yes" />;
  '''

# The following tests were adopted from James Friend's
# https://github.com/jsdf/coffee-react-transform

test 'ambigious tag-like expression', ->
  throws -> CoffeeScript.compile 'x = a <b > c'

test 'ambigious tag', ->
  eqCSX '''
    a <b > c </b>
  ''', '''
    a(<b> c </b>);
  '''

test 'escaped coffeescript attribute', ->
  eqCSX '''
    <Person name={if test() then 'yes' else 'no'} />
  ''', '''
    <Person name={test() ? 'yes' : 'no'} />;
  '''

test 'escaped coffeescript attribute over multiple lines', ->
  eqCSX '''
    <Person name={
      if test()
        'yes'
      else
        'no'
    } />
  ''', '''
    <Person name={test() ? 'yes' : 'no'} />;
  '''

test 'multiple line escaped coffeescript with nested CSX', ->
  eqCSX '''
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
  eqCSX '''
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
  eqCSX '''
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
  eqCSX '''
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

test 'escaped coffeescript with nested object literals', ->
  eqCSX '''
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

test 'multiline tag attributes with escaped coffeescript', ->
  eqCSX '''
    <Person name={if isActive() then 'active' else 'inactive'}
    someattr='on new line' />
  ''', '''
    <Person name={isActive() ? 'active' : 'inactive'} someattr='on new line' />;
  '''

test 'lots of attributes', ->
  eqCSX '''
    <Person eyes={2} friends={getFriends()} popular = "yes"
    active={ if isActive() then 'active' else 'inactive' } data-attr='works' checked check={me_out}
    />
  ''', '''
    <Person eyes={2} friends={getFriends()} popular="yes" active={isActive() ? 'active' : 'inactive'} data-attr='works' checked check={me_out} />;
  '''

# TODO: fix partially indented CSX
# test 'multiline elements', ->
#   eqCSX '''
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
  eqCSX '''
    <Person />
    /\\/\\/<Person \\/>\\>\\//
  ''', '''
    <Person />;

    /\\/\\/<Person \\/>\\>\\//;
  '''

test 'heregex', ->
  eqCSX '''
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

    test = /432/gm;

    6 / 432 / gm;

    <Tag>
    {(test = /<Tag>/)} this is a regex containing something which looks like a tag
    </Tag>;

    <Person />;

    REGEX = /^(\\/(?![s=])[^[\\/ ]*(?:<Tag\\/>(?:\\[sS]|[[^] ]*(?:\\[sS][^] ]*)*<Tag>tag<\\/Tag>])[^[\\/ ]*)*\\/)([imgy]{0,4})(?!w)/;

    <Person />;
  '''

test 'comment within CSX is not treated as comment', ->
  eqCSX '''
    <Person>
    # i am not a comment
    </Person>
  ''', '''
    <Person>
    # i am not a comment
    </Person>;
  '''

test 'comment at start of CSX escape', ->
  eqCSX '''
    <Person>
    {# i am a comment
      "i am a string"
    }
    </Person>
  ''', '''
    <Person>
    {"i am a string"}
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
  eqCSX '''
    <Person> "i am not a string" 'nor am i' </Person>
  ''', '''
    <Person> "i am not a string" 'nor am i' </Person>;
  '''

test 'special chars within CSX are ignored', ->
  eqCSX """
    <Person> a,/';][' a\''@$%^&˚¬∑˜˚∆å∂¬˚*()*&^%$>> '"''"'''\'\'m' i </Person>
  """, """
    <Person> a,/';][' a''@$%^&˚¬∑˜˚∆å∂¬˚*()*&^%$>> '"''"'''''m' i </Person>;
  """

test 'html entities (name, decimal, hex) within CSX', ->
  eqCSX '''
    <Person>  &&&&euro;  &#8364; &#x20AC;;; </Person>
  ''', '''
    <Person>  &&&&euro;  &#8364; &#x20AC;;; </Person>;
  '''

test 'tag with {{}}', ->
  eqCSX '''
    <Person name={{value: item, key, item}} />
  ''', '''
    <Person name={{
        value: item,
        key,
        item
      }} />;
  '''

test 'tag with namespace', ->
  eqCSX '''
    <Something.Tag></Something.Tag>
  ''', '''
    <Something.Tag></Something.Tag>;
  '''

test 'tag with lowercase namespace', ->
  eqCSX '''
    <something.tag></something.tag>
  ''', '''
    <something.tag></something.tag>;
  '''

test 'self closing tag with namespace', ->
  eqCSX '''
    <Something.Tag />
  ''', '''
    <Something.Tag />;
  '''

# TODO: support spread
# test 'self closing tag with spread attribute', ->
#   eqCSX '''
#     <Component a={b} {... x } b="c" />
#   ''', '''
#     React.createElement(Component, Object.assign({"a": (b)},  x , {"b": "c"}))
#   '''

# TODO: support spread
# test 'complex spread attribute', ->
#   eqCSX '''
#     <Component {...x} a={b} {... x } b="c" {...$my_xtraCoolVar123 } />
#   ''', '''
#     React.createElement(Component, Object.assign({},  x, {"a": (b)},  x , {"b": "c"}, $my_xtraCoolVar123  ))
#   '''

# TODO: support spread
# test 'multiline spread attribute', ->
#   eqCSX '''
#     <Component {...
#       x } a={b} {... x } b="c" {...z }>
#     </Component>
#   ''', '''
#     React.createElement(Component, Object.assign({},
#       x , {"a": (b)},  x , {"b": "c"}, z )
#     )
#   '''

# TODO: support spread
# test 'multiline tag with spread attribute', ->
#   eqCSX '''
#     <Component
#       z="1"
#       {...x}
#       a={b}
#       b="c"
#     >
#     </Component>
#   ''', '''
#     React.createElement(Component, Object.assign({ \
#       "z": "1"
#       }, x, { \
#       "a": (b),  \
#       "b": "c"
#     })
#     )
#   '''

# TODO: support spread
# test 'multiline tag with spread attribute first', ->
#   eqCSX '''
#     <Component
#       {...
#       x}
#       z="1"
#       a={b}
#       b="c"
#     >
#     </Component>
#   ''', '''
#     React.createElement(Component, Object.assign({}, \

#       x, { \
#       "z": "1",  \
#       "a": (b),  \
#       "b": "c"
#     })
#     )
#   '''

# TODO: support spread
# test 'complex multiline spread attribute', ->
#   eqCSX '''
#     <Component
#       {...
#       y} a={b} {... x } b="c" {...z }>
#       <div code={someFunc({a:{b:{}, C:'}'}})} />
#     </Component>
#   ''', '''
#     React.createElement(Component, Object.assign({}, \

#       y, {"a": (b)},  x , {"b": "c"}, z ),
#       React.createElement("div", {"code": (someFunc({a:{b:{}, C:'}'}}))})
#     )
#   '''

# TODO: support spread
# test 'self closing spread attribute on single line', ->
#   eqCSX '''
#     <Component a="b" c="d" {...@props} />
#   ''', '''
#     React.createElement(Component, Object.assign({"a": "b", "c": "d"}, @props ))
#   '''

# TODO: support spread
# test 'self closing spread attribute on new line', ->
#   eqCSX '''
#     <Component
#       a="b"
#       c="d"
#       {...@props}
#     />
#   ''', '''
#     React.createElement(Component, Object.assign({ \
#       "a": "b",  \
#       "c": "d"
#       }, @props
#     ))
#   '''

# TODO: support spread
# test 'self closing spread attribute on same line', ->
#   eqCSX '''
#     <Component
#       a="b"
#       c="d"
#       {...@props} />
#   ''', '''
#     React.createElement(Component, Object.assign({ \
#       "a": "b",  \
#       "c": "d"
#       }, @props ))
#   '''

# TODO: support spread
# test 'self closing spread attribute on next line', ->
#   eqCSX '''
#     <Component
#       a="b"
#       c="d"
#       {...@props}

#     />
#   ''', '''
#     React.createElement(Component, Object.assign({ \
#       "a": "b",  \
#       "c": "d"
#       }, @props

#     ))
#   '''

test 'Empty strings are not converted to true', ->
  eqCSX '''
    <Component val="" />
  ''', '''
    <Component val="" />;
  '''

test 'coffeescript @ syntax in tag name', ->
  throws -> CoffeeScript.compile '''
    <@Component>
      <Component />
    </@Component>
  '''

test 'hyphens in tag names', ->
  eqCSX '''
    <paper-button className="button">{text}</paper-button>
  ''', '''
    <paper-button className="button">{text}</paper-button>;
  '''
