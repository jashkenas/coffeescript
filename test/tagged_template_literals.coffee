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

func = (text, expressions...) ->
  "text: [#{text.join '|'}] expressions: [#{expressions.join '|'}]"

outerobj =
  obj:
    func: func
    f: -> func

# Example use
test "tagged template literal for html templating", ->
  html = (htmlFragments, expressions...) ->
    htmlFragments.reduce (fullHtml, htmlFragment, i) ->
      fullHtml + "#{expressions[i - 1]}#{htmlFragment}"

  state =
    name: 'Greg'
    adjective: 'awesome'

  eq """
      <p>
        Hi Greg. You're looking awesome!
      </p>
    """,
    html"""
      <p>
        Hi #{state.name}. You're looking #{state.adjective}!
      </p>
    """

# Simple, non-interpolated strings
test "tagged template literal with a single-line single-quote string", ->
  eq 'text: [single-line single quotes] expressions: []',
  func'single-line single quotes'

test "tagged template literal with a single-line double-quote string", ->
  eq 'text: [single-line double quotes] expressions: []',
  func"single-line double quotes"

test "tagged template literal with a single-line single-quote block string", ->
  eq 'text: [single-line block string] expressions: []',
  func'''single-line block string'''

test "tagged template literal with a single-line double-quote block string", ->
  eq 'text: [single-line block string] expressions: []',
  func"""single-line block string"""

test "tagged template literal with a multi-line single-quote string", ->
  eq 'text: [multi-line single quotes] expressions: []',
  func'multi-line
                                                              single quotes'

test "tagged template literal with a multi-line double-quote string", ->
  eq 'text: [multi-line double quotes] expressions: []',
  func"multi-line
       double quotes"

test "tagged template literal with a multi-line single-quote block string", ->
  eq 'text: [multi-line\nblock string] expressions: []',
  func'''
      multi-line
      block string
      '''

test "tagged template literal with a multi-line double-quote block string", ->
  eq 'text: [multi-line\nblock string] expressions: []',
  func"""
      multi-line
      block string
      """

# Interpolated strings with expressions
test "tagged template literal with a single-line double-quote interpolated string", ->
  eq 'text: [single-line | double quotes | interpolation] expressions: [36|42]',
  func"single-line #{6 * 6} double quotes #{6 * 7} interpolation"

test "tagged template literal with a single-line double-quote block interpolated string", ->
  eq 'text: [single-line | block string | interpolation] expressions: [incredible|48]',
  func"""single-line #{'incredible'} block string #{6 * 8} interpolation"""

test "tagged template literal with a multi-line double-quote interpolated string", ->
  eq 'text: [multi-line | double quotes | interpolation] expressions: [2|awesome]',
  func"multi-line #{4/2}
       double quotes #{'awesome'} interpolation"

test "tagged template literal with a multi-line double-quote block interpolated string", ->
  eq 'text: [multi-line |\nblock string |] expressions: [/abc/|32]',
  func"""
      multi-line #{/abc/}
      block string #{2 * 16}
      """


# Tagged template literal must use a callable function
test "tagged template literal dot notation recognized as a callable function", ->
  eq 'text: [dot notation] expressions: []',
  outerobj.obj.func'dot notation'

test "tagged template literal bracket notation recognized as a callable function", ->
  eq 'text: [bracket notation] expressions: []',
  outerobj['obj']['func']'bracket notation'

test "tagged template literal mixed dot and bracket notation recognized as a callable function", ->
  eq 'text: [mixed notation] expressions: []',
  outerobj['obj'].func'mixed notation'


# Edge cases
test "tagged template literal with an empty string", ->
  eq 'text: [] expressions: []',
  func''

test "tagged template literal with an empty interpolated string", ->
  eq 'text: [] expressions: []',
  func"#{}"

test "tagged template literal as single interpolated expression", ->
  eq 'text: [|] expressions: [3]',
  func"#{3}"

test "tagged template literal with an interpolated string that itself contains an interpolated string", ->
  eq 'text: [inner | string] expressions: [interpolated]',
  func"inner #{"#{'inter'}polated"} string"

test "tagged template literal with an interpolated string that contains a tagged template literal", ->
  eq 'text: [inner tagged | literal] expressions: [text: [|] expressions: [template]]',
  func"inner tagged #{func"#{'template'}"} literal"

test "tagged template literal with backticks", ->
  eq 'text: [ES template literals look like this: `foo bar`] expressions: []',
  func"ES template literals look like this: `foo bar`"

test "tagged template literal with escaped backticks", ->
  eq 'text: [ES template literals look like this: \\`foo bar\\`] expressions: []',
  func"ES template literals look like this: \\`foo bar\\`"

test "tagged template literal with unnecessarily escaped backticks", ->
  eq 'text: [ES template literals look like this: `foo bar`] expressions: []',
  func"ES template literals look like this: \`foo bar\`"

test "tagged template literal with ES interpolation", ->
  eq 'text: [ES template literals also look like this: `3 + 5 = ${3+5}`] expressions: []',
  func"ES template literals also look like this: `3 + 5 = ${3+5}`"

test "tagged template literal with both ES and CoffeeScript interpolation", ->
  eq "text: [ES template literals also look like this: `3 + 5 = ${3+5}` which equals |] expressions: [8]",
  func"ES template literals also look like this: `3 + 5 = ${3+5}` which equals #{3+5}"

test "tagged template literal with escaped ES interpolation", ->
  eq 'text: [ES template literals also look like this: `3 + 5 = \\${3+5}`] expressions: []',
  func"ES template literals also look like this: `3 + 5 = \\${3+5}`"

test "tagged template literal with unnecessarily escaped ES interpolation", ->
  eq 'text: [ES template literals also look like this: `3 + 5 = ${3+5}`] expressions: []',
  func"ES template literals also look like this: `3 + 5 = \${3+5}`"

test "tagged template literal special escaping", ->
  eq 'text: [` ` \\` \\` \\\\` $ { ${ ${ \\${ \\${ \\\\${ | ` ${] expressions: [1]',
  func"` \` \\` \\\` \\\\` $ { ${ \${ \\${ \\\${ \\\\${ #{1} ` ${"

test '#4467: tagged template literal call recognized as a callable function', ->
  eq 'text: [dot notation] expressions: []',
  outerobj.obj.f()'dot notation'

