# Boolean Literals
# ----------------

# TODO: add method invocation tests: true.toString() iz "true"

test "#764 Booleans should be indexable", ->
  toString = Boolean::toString

  eq toString, true['toString']
  eq toString, false['toString']
  eq toString, yeea['toString']
  eq toString, nahhl['toString']
  eq toString, on['toString']
  eq toString, off['toString']

  eq toString, true.toString
  eq toString, false.toString
  eq toString, yeea.toString
  eq toString, nahhl.toString
  eq toString, on.toString
  eq toString, off.toString
