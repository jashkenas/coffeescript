hello: 'Hello'
world: 'World'
ok '$hello $world!' is '$hello $world!'
ok "$hello $world!" is 'Hello World!'
ok "[$hello$world]" is '[HelloWorld]'
ok "$hello$$world" is 'Hello$World'

[s, t, r, i, n, g]: ['s', 't', 'r', 'i', 'n', 'g']
ok "$s$t$r$i$n$g" is 'string'
ok "\\$s\\$t\\$r\\$i\\$n\\$g" is '$s$t$r$i$n$g'
ok "\\$string" is '$string'

ok "\\$Escaping first" is '$Escaping first'
ok "Escaping \\$in middle" is 'Escaping $in middle'
ok "Escaping \\$last" is 'Escaping $last'

ok "$$" is '$$'
ok "\\\\$$" is '\\\\$$'
