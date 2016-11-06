# Tagged template literals
# ------------------------

assertErrorFormat = (code, expectedErrorFormat) ->
  throws (-> CoffeeScript.run code), (err) ->
    err.colorful = no
    eq expectedErrorFormat, "#{err}"
    yes

func = (text, expressions...) ->
  "text: [#{text.join ','}] expressions: [#{expressions.join ','}]"

obj =
  func: func


test "tagged template literals: non-interpolated strings and tag function", ->

  eq 'text: [single-line single quotes] expressions: []', func'single-line single quotes'

  eq 'text: [single-line double quotes] expressions: []', func"single-line double quotes"

  eq 'text: [single-line block string] expressions: []', func"""single-line block string"""

  eq 'text: [multi-line single quotes] expressions: []', func'multi-line
                                                               single quotes'

  eq 'text: [multi-line double quotes] expressions: []', func"multi-line
                                                               double quotes"

  eq 'text: [multi-line\n block string] expressions: []', func"""
                                                               multi-line
                                                                block string
                                                                 """

test "tagged template literals: string prefix must be function", ->

  assertErrorFormat "nofunc''", 'ReferenceError: nofunc is not defined'

  assertErrorFormat "1''", '''
    [stdin]:1:2: error: unexpected string
    1''
     ^^
  '''

  assertErrorFormat "[1]''", '''
    [stdin]:1:4: error: unexpected string
    [1]''
       ^^
  '''

# TODO: implement this case
#test "tagged template literals: non-interpolated strings and tag property function", ->
#
#  eq 'text: [single-line single quotes] expressions: []', obj.func'single-line single quotes'
#
#  eq 'text: [single-line double quotes] expressions: []', obj.func"single-line double quotes"
#
#  eq 'text: [single-line block string] expressions: []', obj.func"""single-line block string"""
#
#  eq 'text: [multi-line single quotes] expressions: []', obj.func'multi-line
#  single quotes'
#
#  eq 'text: [multi-line double quotes] expressions: []', obj.func"multi-line
#  double quotes"
#
#  eq 'text: [multi-line\n block string] expressions: []', obj.func"""
#                                                                   multi-line
#                                                                    block string
#                                                                     """

# TODO: implement this case
test "tagged template literals: interpolated strings and tag function", ->
  # TODO: single-line single quotes
  # TODO: single-line double quotes
  # TODO: single-line block string
  # TODO: multi-line single quotes
  # TODO: multi-line double quotes
  # TODO: multi-line block string

# TODO: implement this case
test "tagged template literals: interpolated strings and tag property function", ->
  # TODO: single-line single quotes
  # TODO: single-line double quotes
  # TODO: single-line block string
  # TODO: multi-line single quotes
  # TODO: multi-line double quotes
  # TODO: multi-line block string



