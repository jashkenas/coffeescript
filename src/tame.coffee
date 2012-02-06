
# =======================================================================
# Compile Time!
#
exports.transform = (x) ->
  x.tameTransform()

exports.const = 
  k : "__tame_k"
  param : "__tame_p_"
  ns: "tame"
  Deferrals : "Deferrals"
  deferrals : "__tame_deferrals"
  fulfill : "_fulfill"
  b_while : "_break"
  t_while : "_while"
  c_while : "_continue"
  n_while : "_next"
  n_arg   : "__tame_next_arg"
  defer_method : "defer"
  slot : "__slot"
  assign_fn : "assign_fn"
  runtime : "tamerun"
  autocb : "autocb"
  retslot : "ret"

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
# 
# Tick Counter --
#    count off every mod processor ticks
# 
__c = 0

tickCounter = (mod) ->
  __c++
  if (__c % mod) == 0
    __c = 0
    true
  else
    false

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
    @ret = null

  _fulfill : ->
    if --@count == 0
      if tickCounter 500
        process.nextTick (=> @continuation @ret)
      else
        @continuation @ret

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
    # This is a hack to work with the desugaring of
    # 'defer' output by the coffee compiler.
    @[exports.const.deferrals] = this

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
    ret = {}
    ret[exports.const.deferrals] = new RvId(this, i)
    ret
  
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
