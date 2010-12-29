
{RESERVED} = require './coffee-script'
Script = process.binding('evals').Script

# Return elements of candidates for which `prefix` is a prefix.
get_completions = (prefix, candidates) ->
  (el for el in candidates when el.indexOf(prefix) == 0)

get_property_names = (o) ->
  try
    Object.getOwnPropertyNames(o)
  catch error
    (k for k of o)

complete_attribute = (text) ->
  match = /\s*([\w\.]+)(?:\.(\w*))$/.exec(text)
  if match?
    [ob, prefix] = [match[1], match[2]]
    try
      val = Script.runInThisContext ob
    catch error
      return [[], text]
    completions = get_completions prefix, get_property_names val
    [completions, prefix]

complete_variable = (text) ->
  free = /\W*(\w*)$/i.exec(text)?[1]
  if free?
    completions = get_completions free, RESERVED.concat(get_property_names Script.runInThisContext 'this')
    [completions, free]

# Returns a list of completions and the completed text
exports.complete = (text) ->
  complete_attribute(text) or complete_variable(text) or [[], text]
