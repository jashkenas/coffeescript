
# =======================================================================
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
#   A collection of Deferrals; this is a better version than the one
#   that's inline; it allows for tame tracing
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

class Rendezvous
  constructor: ->
    @completed = []
    @waiters = []
    @defer_id = 0
    # This is a hack to work with the semantic desugaring of
    # 'defers' output by the coffee compiler.
    @__tame_defers = this

  #-----------------------------------------
    
  class RvId
    constructor: (@rv,@id)->
    defer: (defer_args) ->
      @rv._deferWithId @id, defer_args

  #-----------------------------------------
  # 
  # The public interface has 3 methods --- wait, defer and id
  wait: (cb) ->
    if @completed.length
      x = @completed.shift()
      cb(x)
    else
      @waiters.push cb

  #-----------------------------------------

  defer: (defer_args) ->
    id = @defer_id++
    @deferWithId id, defer_args

  #-----------------------------------------
  
  id: (i) ->
    { __tame_defers : new @RvId(this, i) }
  
  #-----------------------------------------

  _fulfill: (id) ->
    if @waiters.length
      cb = @waiters.shift()
      cb(id)
    else
      @completed.push id

  #-----------------------------------------
  
  _deferWithId: (id, defer_args) ->
    @count++
    makeDeferReturn this, defer_args, id

#=======================================================================

exports.runtime = { Deferrals, Rendezvous }

#=======================================================================
