num = 10
num -= 5
eq num, 5

num *= 10
eq num, 50

num /= 10
eq num, 5

num %= 3
eq num, 2

val = false
val ||= 'value'
val ||= 'eulav'
eq val, 'value'

val &&= 'rehto'
val &&= 'other'
eq val, 'other'

val = null
val ?= 'value'
val ?= 'eulav'
eq val, 'value'
