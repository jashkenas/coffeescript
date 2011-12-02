
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

#=======================================================================
# runtime

makeDeferReturn = (obj, defer_args, id) ->
  ret = (inner_args...) ->
    defer_args?.assign_fn?.apply(null, inner_args)
    obj._fulfill id

  if defer_args
    ret.__tame_trace = {}
    for k in [ "parent_cb", "file", "line", "func_name" ]
      ret.__tame_trace[k] = defer_args[k]

  ret

#-----------------------------------------------------------------------
# Deferrals
#
#   A collection of Deferrals that can
#
class Deferrals

  constructor: (k) ->
    @continuation = k
    @count = 1

  _fulfill : ->
    @continuation() if --@count == 0

  defer : (args) ->
    @count++
    self = this
    return makeDeferReturn self, args, null

#=======================================================================

exports.runtime = { Deferrals }
