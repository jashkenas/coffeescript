hello: 'Hello'
world: 'World'
ok '$hello $world!' is '$hello $world!'
ok '${hello} ${world}!' is '${hello} ${world}!'
ok "$hello $world!" is 'Hello World!'
ok "${hello} ${world}!" is 'Hello World!'
ok "[$hello$world]" is '[HelloWorld]'
ok "[${hello}${world}]" is '[HelloWorld]'
ok "$hello$$world" is 'Hello$World'
ok "${hello}$${world}" is 'Hello$World'
ok "Hello ${ 1 + 2 } World" is 'Hello 3 World'
ok "$hello ${ 1 + 2 } $world" is "Hello 3 World"

[s, t, r, i, n, g]: ['s', 't', 'r', 'i', 'n', 'g']
ok "$s$t$r$i$n$g" is 'string'
ok "${s}${t}${r}${i}${n}${g}" is 'string'
ok "\$s\$t\$r\$i\$n\$g" is '$s$t$r$i$n$g'
ok "\\$s\\$t\\$r\\$i\\$n\\$g" is '\\s\\t\\r\\i\\n\\g'
ok "\${s}\${t}\${r}\${i}\${n}\${g}" is '${s}${t}${r}${i}${n}${g}'
ok "\$string" is '$string'
ok "\${string}" is '${string}'

ok "\$Escaping first" is '$Escaping first'
ok "\${Escaping} first" is '${Escaping} first'
ok "Escaping \$in middle" is 'Escaping $in middle'
ok "Escaping \${in} middle" is 'Escaping ${in} middle'
ok "Escaping \$last" is 'Escaping $last'
ok "Escaping \${last}" is 'Escaping ${last}'

ok "$$" is '$$'
ok "${}" is '${}'
ok "\\\\\$$" is '\\\\\$$'
ok "\\\${}" is '\\${}'

ok "I won $20 last night." is 'I won $20 last night.'
ok "I won $${20} last night." is 'I won $20 last night.'
ok "I won $#20 last night." is 'I won $#20 last night.'
ok "I won $${'#20'} last night." is 'I won $#20 last night.'

ok "${hello + world}" is 'HelloWorld'
ok "${hello + ' ' + world + '!'}" is 'Hello World!'

list: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
ok "values: ${list.join(', ')}, length: ${list.length}." is 'values: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, length: 10.'
ok "values: ${list.join ' '}" is 'values: 0 1 2 3 4 5 6 7 8 9'

obj: {
  name: 'Joe'
  hi: -> "Hello $@name."
}
ok obj.hi() is "Hello Joe."

ok "I can has ${"cheeze"}" is 'I can has cheeze'
ok 'I can has ${"cheeze"}' is 'I can has ${"cheeze"}'

ok "Where is ${obj["name"] + '?'}" is 'Where is Joe?'

ok "Where is ${"the new ${obj["name"]}"}?" is 'Where is the new Joe?'
ok "Hello ${world ? "$hello"}" is 'Hello World'

ok "Hello ${"${"${obj["name"]}" + '!'}"}" is 'Hello Joe!'
