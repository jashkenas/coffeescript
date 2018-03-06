# Boolean Literals
# ----------------

# TODO: add method invocation tests: true.toString() is "true"

test "#764 Booleans should be indexable", ->
  toString = Boolean::toString

  eq toString, true['toString']
  eq toString, false['toString']
  eq toString, yes['toString']
  eq toString, no['toString']
  eq toString, on['toString']
  eq toString, off['toString']

  eq toString, true.toString
  eq toString, false.toString
  eq toString, yes.toString
  eq toString, no.toString
  eq toString, on.toString
  eq toString, off.toString
