
#=======================================================================
# Compile Time!
# 
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
  b_while : "_break"
  t_while : "_while"
  c_while : "_continue"
  defer_method : "defer"
  slot : "__slot"
  assign_fn : "assign_fn"
  runtime : "tamerun"


