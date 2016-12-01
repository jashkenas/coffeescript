# See http://wiki.ecmascript.org/doku.php?id=harmony:egal
egal = (a, b) ->
  if a is b
    a isnt 0 or 1/a is 1/b
  else
    a isnt a and b isnt b

# A recursive functional equivalence helper; uses egal for testing equivalence.
arrayEgal = (a, b) ->
  if egal a, b then yes
  else if a instanceof Array and b instanceof Array
    return no unless a.length is b.length
    return no for el, idx in a when not arrayEgal el, b[idx]
    yes

exports.eq      = (a, b, msg) -> ok egal(a, b), msg or "Expected #{a} to equal #{b}"
exports.arrayEq = (a, b, msg) -> ok arrayEgal(a,b), msg or "Expected #{a} to deep equal #{b}"
