
exports.AstTamer = class AstTamer

    constructor: (rest...) ->

    transform: (x) ->
      x.tameTransform()

exports.const =
  k : "__tame_k"
  ns: "tame"
  Deferrals : "Deferrals"
  deferrals : "__tame_deferrals"
  fulfill : "_fulfill"
  k_while : "_kw"
