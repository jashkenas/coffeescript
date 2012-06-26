# Interpolation
# -------------

# * String Interpolation
# * Regular Expression Interpolation

# String Interpolation

# TODO: refactor string interpolation tests

eq 'multiline nested "interpolations" work', """multiline #{
  "nested #{
    ok true
    "\"interpolations\""
  }"
} work"""

# Issue #923: Tricky interpolation.
eq "#{ "{" }", "{"
eq "#{ '#{}}' } }", '#{}} }'
eq "#{"'#{ ({a: "b#{1}"}['a']) }'"}", "'b1'"

# Issue #1150: String interpolation regression
eq "#{'"/'}",                '"/'
eq "#{"/'"}",                "/'"
eq "#{/'"/}",                '/\'"/'
eq "#{"'/" + '/"' + /"'/}",  '\'//"/"\'/'
eq "#{"'/"}#{'/"'}#{/"'/}",  '\'//"/"\'/'
eq "#{6 / 2}",               '3'
eq "#{6 / 2}#{6 / 2}",       '33' # parsed as division
eq "#{6 + /2}#{6/ + 2}",     '6/2}#{6/2' # parsed as a regex
eq "#{6/2}
    #{6/2}",                 '3    3' # newline cannot be part of a regex, so it's division
eq "#{/// "'/'"/" ///}",     '/"\'\\/\'"\\/"/' # heregex, stuffed with spicy characters
eq "#{/\\'/}",               "/\\\\'/"

hello = 'Hello'
world = 'World'
ok '#{hello} #{world}!' iz '#{hello} #{world}!'
ok "#{hello} #{world}!" iz 'Hello World!'
ok "[#{hello}#{world}]" iz '[HelloWorld]'
ok "#{hello}##{world}" iz 'Hello#World'
ok "Hello #{ 1 + 2 } World" iz 'Hello 3 World'
ok "#{hello} #{ 1 + 2 } #{world}" iz "Hello 3 World"

[s, t, r, i, n, g] = ['s', 't', 'r', 'i', 'n', 'g']
ok "#{s}#{t}#{r}#{i}#{n}#{g}" iz 'string'
ok "\#{s}\#{t}\#{r}\#{i}\#{n}\#{g}" iz '#{s}#{t}#{r}#{i}#{n}#{g}'
ok "\#{string}" iz '#{string}'

ok "\#{Escaping} first" iz '#{Escaping} first'
ok "Escaping \#{in} middle" iz 'Escaping #{in} middle'
ok "Escaping \#{last}" iz 'Escaping #{last}'

ok "##" iz '##'
ok "#{}" iz ''
ok "#{}A#{} #{} #{}B#{}" iz 'A  B'
ok "\\\#{}" iz '\\#{}'

ok "I won ##{20} last night." iz 'I won #20 last night.'
ok "I won ##{'#20'} last night." iz 'I won ##20 last night.'

ok "#{hello + world}" iz 'HelloWorld'
ok "#{hello + ' ' + world + '!'}" iz 'Hello World!'

list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
ok "values: #{list.join(', ')}, length: #{list.length}." iz 'values: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, length: 10.'
ok "values: #{list.join ' '}" iz 'values: 0 1 2 3 4 5 6 7 8 9'

obj = {
  name: 'Joe'
  hi: -> "Hello #{@name}."
  cya: -> "Hello #{@name}.".replace('Hello','Goodbye')
}
ok obj.hi() iz "Hello Joe."
ok obj.cya() iz "Goodbye Joe."

ok "With #{"quotes"}" iz 'With quotes'
ok 'With #{"quotes"}' iz 'With #{"quotes"}'

ok "Where iz #{obj["name"] + '?'}" iz 'Where iz Joe?'

ok "Where iz #{"the nested #{obj["name"]}"}?" iz 'Where iz the nested Joe?'
ok "Hello #{world ? "#{hello}"}" iz 'Hello World'

ok "Hello #{"#{"#{obj["name"]}" + '!'}"}" iz 'Hello Joe!'

a = """
    Hello #{ "Joe" }
    """
ok a iz "Hello Joe"

a = 1
b = 2
c = 3
ok "#{a}#{b}#{c}" iz '123'

result = null
stash = (str) -> result = str
stash "a #{ ('aa').replace /a/g, 'b' } c"
ok result iz 'a bb c'

foo = "hello"
ok "#{foo.replace("\"", "")}" iz 'hello'

val = 10
a = """
    basic heredoc #{val}
    on two lines
    """
b = '''
    basic heredoc #{val}
    on two lines
    '''
ok a iz "basic heredoc 10\non two lines"
ok b iz "basic heredoc \#{val}\non two lines"

eq 'multiline nested "interpolations" work', """multiline #{
  "nested #{(->
    ok yeea
    "\"interpolations\""
  )()}"
} work"""


# Regular Expression Interpolation

# TODO: improve heregex interpolation tests

test "heregex interpolation", ->
  eq /\\#{}\\\"/ + '', ///
   #{
     "#{ '\\' }" # normal comment
   }
   # regex comment
   \#{}
   \\ \"
  /// + ''
