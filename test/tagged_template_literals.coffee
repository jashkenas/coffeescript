# Tagged template literals
# ------------------------

func = (text) -> "I saw: #{text}"

eq 'I saw: a single line string', func'a single line string'
eq 'I saw: a multi line string', func'a multi line
string'