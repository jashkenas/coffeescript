upperCaseExpr = (textParts, expressions...) ->
  textParts.reduce (text, textPart, i) ->
    text + expressions[i - 1].toUpperCase() + textPart

name = "greg"
adjective = "awesome"

text = upperCaseExpr"""
                    Hi #{name}. You look #{adjective}!
                    """