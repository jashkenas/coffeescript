upperCaseExpr = (textParts, expressions...) ->
  textParts.reduce (text, textPart, i) ->
    text + expressions[i - 1].toUpperCase() + textPart

greet = (name, adjective) ->
  upperCaseExpr"""
               Hi #{name}. You look #{adjective}!
               """
