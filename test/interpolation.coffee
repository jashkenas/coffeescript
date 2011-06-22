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
ok '#{hello} #{world}!' is '#{hello} #{world}!'
ok "#{hello} #{world}!" is 'Hello World!'
ok "[#{hello}#{world}]" is '[HelloWorld]'
ok "#{hello}##{world}" is 'Hello#World'
ok "Hello #{ 1 + 2 } World" is 'Hello 3 World'
ok "#{hello} #{ 1 + 2 } #{world}" is "Hello 3 World"

[s, t, r, i, n, g] = ['s', 't', 'r', 'i', 'n', 'g']
ok "#{s}#{t}#{r}#{i}#{n}#{g}" is 'string'
ok "\#{s}\#{t}\#{r}\#{i}\#{n}\#{g}" is '#{s}#{t}#{r}#{i}#{n}#{g}'
ok "\#{string}" is '#{string}'

ok "\#{Escaping} first" is '#{Escaping} first'
ok "Escaping \#{in} middle" is 'Escaping #{in} middle'
ok "Escaping \#{last}" is 'Escaping #{last}'

ok "##" is '##'
ok "#{}" is ''
ok "#{}A#{} #{} #{}B#{}" is 'A  B'
ok "\\\#{}" is '\\#{}'

ok "I won ##{20} last night." is 'I won #20 last night.'
ok "I won ##{'#20'} last night." is 'I won ##20 last night.'

ok "#{hello + world}" is 'HelloWorld'
ok "#{hello + ' ' + world + '!'}" is 'Hello World!'

list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
ok "values: #{list.join(', ')}, length: #{list.length}." is 'values: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, length: 10.'
ok "values: #{list.join ' '}" is 'values: 0 1 2 3 4 5 6 7 8 9'

obj = {
  name: 'Joe'
  hi: -> "Hello #{@name}."
  cya: -> "Hello #{@name}.".replace('Hello','Goodbye')
}
ok obj.hi() is "Hello Joe."
ok obj.cya() is "Goodbye Joe."

ok "With #{"quotes"}" is 'With quotes'
ok 'With #{"quotes"}' is 'With #{"quotes"}'

ok "Where is #{obj["name"] + '?'}" is 'Where is Joe?'

ok "Where is #{"the nested #{obj["name"]}"}?" is 'Where is the nested Joe?'
ok "Hello #{world ? "#{hello}"}" is 'Hello World'

ok "Hello #{"#{"#{obj["name"]}" + '!'}"}" is 'Hello Joe!'

a = """
    Hello #{ "Joe" }
    """
ok a is "Hello Joe"

a = 1
b = 2
c = 3
ok "#{a}#{b}#{c}" is '123'

result = null
stash = (str) -> result = str
stash "a #{ ('aa').replace /a/g, 'b' } c"
ok result is 'a bb c'

foo = "hello"
ok "#{foo.replace("\"", "")}" is 'hello'

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

eq 'multiline nested "interpolations" work', """multiline #{
  "nested #{(->
    ok yes
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
