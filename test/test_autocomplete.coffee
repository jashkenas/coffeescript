return unless require?

complete = require './../lib/autocomplete'

eq_set = (left, right) ->
  left = left.slice(0)
  right = right.slice(0)
  left.sort()
  right.sort()
  eq left.join(' '), right.join(' ')

# JavaScript keywords
[completions, completed] = complete.complete "c"
ok completions instanceof Array
should_be = ["case", "catch", "class", "clearInterval", "clearTimeout", "console", "const", "continue"]
eq_set should_be, completions

[completions, completed] = complete.complete 'E'
eq_set completions, ['EvalError', 'Error']

[completions, completed] = complete.complete "Math.c"
eq_set completions, ["cos", "ceil"]

# I don't know how to make this testable :(
# a = {baba: 1, babo: 2}

# [completions, completed] = complete.complete "a.bab"
# eq_set completions, ["baba", "babo"]




