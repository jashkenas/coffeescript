name: 'Bob'

ok not not '"Bob"'.match(/^"${name}"$/i)
ok '"Bobby"'.match(/^"${name}"$/i) is null

ok not not 'Bob'.match(/^$name$/)
ok 'Bobby'.match(/^$name/)

ok 'Bobby'.match(/${"${"${"$name"}"}"}/imgy)

ok '$a$b$c'.match(/\$A\$B\$C/i)

a: 1
b: 2
c: 3
ok '123'.match(/$a$b$c/i)

[a, b, c]: [1, 2, /\d+/]
ok (/$a$b$c$/i).toString() is '/12/\\d+/$/i'
