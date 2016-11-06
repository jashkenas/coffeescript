# Tagged template literals
# ------------------------

# NOTES:
# A tagged template literal is a string that is passed to a prefixing function for
# post-processing. There's a bunch of different angles that need testing:
# - Prefixing function, which can be any form of function call:
#   - function: func'Hello'
#   - object property with dot notation: outerobj.obj.func'Hello'
#   - object property with bracket notation: outerobj['obj']['func']'Hello'
# - String form: single quotes, double quotes and block strings
# - String is single-line or multi-line
# - String is interpolated or not

assertErrorFormat = (code, expectedErrorFormat) ->
  throws (-> CoffeeScript.run code), (err) ->
    err.colorful = no
    eq expectedErrorFormat, "#{err}"
    yes

func = (text, expressions...) ->
  "text: [#{text.join '|'}] expressions: [#{expressions.join '|'}]"

outerobj =
  obj:
    func: func


test "tagged template literals: non-interpolated strings", ->

  eq 'text: [single-line single quotes] expressions: []', func'single-line single quotes'

  eq 'text: [single-line double quotes] expressions: []', func"single-line double quotes"

  eq 'text: [single-line block string] expressions: []', func"""single-line block string"""

  eq 'text: [multi-line single quotes] expressions: []', func'multi-line
                                                              single quotes'

  eq 'text: [multi-line double quotes] expressions: []', func"multi-line
                                                              double quotes"

  eq 'text: [multi-line\nblock string] expressions: []', func"""
                                                                multi-line
                                                                block string
                                                             """

test "tagged template literals: interpolated strings and tag function", ->

#  eq 'text: [single-line double quotes | interpolation] expressions: [42]', func"single-line double quotes #{6 * 7} interpolation"

#  # TODO: single-line block string interpolation
#  # TODO: multi-line double quotes interpolation
#  # TODO: multi-line block string interpolation

test "tagged template literals: string prefix must be a callable function", ->

  eq 'text: [dot notation] expressions: []', outerobj.obj.func'dot notation'

  eq 'text: [bracket notation] expressions: []', outerobj['obj']['func']'bracket notation'

  eq 'text: [mixed notation] expressions: []', outerobj['obj'].func'mixed notation'

  # TODO: Put tests below in test/error_messages.coffee?
  #       Currently here as they show invalid forms of tagged template literals

  assertErrorFormat "nofunc''", 'ReferenceError: nofunc is not defined'

  assertErrorFormat "1''", '''
    [stdin]:1:1: error: literal is not a function
    1''
    ^
  '''

  assertErrorFormat "[1]''", '''
    [stdin]:1:1: error: literal is not a function
    [1]''
    ^^^
  '''

