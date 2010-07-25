num = 10
num -= 5

ok num is 5

num = -3

ok num is -3

num = +3

ok num is 3

num *= 10

ok num is 30

num /= 10

ok num is 3


val = false
val ||= 'value'

ok val is 'value'

val &&= 'other'

ok val is 'other'


val = null
val ?= 'value'

ok val is 'value'


val = 6
val = -(10)

ok val is -10

val -= (10)
ok val is -20