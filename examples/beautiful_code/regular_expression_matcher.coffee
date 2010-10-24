# Beautiful Code, Chapter 1.
# Implements a regular expression matcher that supports character matches,
# '.', '^', '$', and '*'.

# Search for the regexp anywhere in the text.
match = (regexp, text) ->
  return match_here(regexp.slice(1), text) if regexp[0] is '^'
  while text
    return true if match_here(regexp, text)
    text = text.slice(1)
  false

# Search for the regexp at the beginning of the text.
match_here = (regexp, text) ->
  [cur, next] = [regexp[0], regexp[1]]
  if regexp.length is 0 then return true
  if next is '*' then return match_star(cur, regexp.slice(2), text)
  if cur is '$' and not next then return text.length is 0
  if text and (cur is '.' or cur is text[0]) then return match_here(regexp.slice(1), text.slice(1))
  false

# Search for a kleene star match at the beginning of the text.
match_star = (c, regexp, text) ->
  loop
    return true if match_here(regexp, text)
    return false unless text and (text[0] is c or c is '.')
    text = text.slice(1)

console.log match("ex", "some text")
console.log match("s..t", "spit")
console.log match("^..t", "buttercup")
console.log match("i..$", "cherries")
console.log match("o*m", "vrooooommm!")
console.log match("^hel*o$", "hellllllo")