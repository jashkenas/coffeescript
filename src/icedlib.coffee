icedRequire(none)

tame_internals = require('./tame')
tame = tame_internals.runtime

#
# tamelib
#
#   This class contains non-essential but convenient runtime libraries
#   for tame programs
# 

#
# The `timeout` connector, which allows us to compose timeouts with
# existing event-based calls
#  
_timeout = (cb, t, res, tmp) ->
    rv = new tame.Rendezvous
    tmp[0] = rv.id(true).defer(arr...)
    setTimeout rv.id(false).defer(), t
    await rv.wait defer which
    res[0] = which if res
    cb.apply(null, arr)

exports.timeout = (cb, t, res) ->    
  tmp = []
  _timeout cb, t, res, tmp
  tmp[0]

####
# 
# Pipeliner -- a class for firing a follow of network calls in a pipelined
#   fashion, so that only so many of them are outstanding at once.
# 
exports.Pipeliner = class Pipeliner

  constructor : (window, delay) ->
    @window = window || 1
    @delay = delay || 0
    @queue = []
    @n_out = 0
    @cb = null
    
    # This is a hack to work with the desugaring of
    # 'defer' output by the coffee compiler. Same as in rendezvous
    @[tame_internals.const.deferrals] = this
    
    # Rebind "defer" to "_defer"; We can't do this directly since the
    # compiler would pick it up
    @["defer"] = @_defer
    

  # Call this to wait in a queue until there is room in the window
  waitInQueue : (cb) ->
  
    # Wait until there is room in the window.
    while @n_out > @window
      await (@cb = defer())

    # Lanuch a computation, so mark that there's one more
    # guy outstanding.
    @n_out++
      
    # Delay if that was asked for...
    if @delay
      await setTimeout defer(), @delay
      
    cb()
        

  # Helper for this._defer, seen below..
  __defer : (out, deferArgs) ->

    # Make a callback that this.defer can return.
    # This callback might have to fill in slots when its
    # fulfilled, so that's why we need to wrap the output
    # of defer() in an anonymous wrapper.
    await
      voidCb = defer()
      out[0] = (args...) ->
        deferArgs.assign_fn?.apply null, args
        voidCb()

    # There is now one fewer outstanding computation.
    @n_out--

    # If some is waiting in waitInQueue above, then now is the
    # time to release him. Use "race-free" callback technique.
    if @cb
      tmp = @cb
      @cb = null
      tmp()

  # This function, Pipeliner._defer, has to return a 
  # callback to its caller.  It does this with the same trick above.
  # The helper function _defer() does the heavy lifting, returning
  # its callback to us as the first slot in tmp[0].
  _defer : (deferArgs) ->
    tmp = []
    @__defer tmp, deferArgs
    tmp[0]

  # flush everything left in the pipe
  flush : (autocb) ->
    while @n_out
      await (@cb = defer())

