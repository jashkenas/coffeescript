  
#=======================================================================

makeDeferReturn = (obj, defer_args, id) ->
  ret = (inner_args...) ->
    defer_args?.assign_fn?.apply(null, inner_args)
    obj._fulfill id

  if defer_args
    ret.__tame_trace = {}
    for k in [ "parent_cb", "file", "line", "func_name" ]
      ret.__tame_trace[k] = defer_args[k]

  ret

#=======================================================================
# Deferrals
# 
#   A collection of Deferrals that can
# 
exports.Deferrals = class Deferrals

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
