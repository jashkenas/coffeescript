{ Console } = require 'console'
process     = require 'process'

exports.CakeConsole = class CakeConsole extends Console
  @LEVELS: ['trace', 'debug', 'info', 'log', 'warn', 'error']
  @validLevels: => "[#{(@LEVELS.map (l) -> "'#{l}'").join ', '}]"
  @checkLevel: (level) =>
    unless level in @LEVELS
      throw new TypeError "argument '#{level}' was not a valid log level (should be: #{@validLevels()})"
    level

  constructor: ({level, ...opts} = {}) ->
    super opts
    @level = @constructor.checkLevel level ? 'log'

  @getLevelNum: (l) => @LEVELS.indexOf @checkLevel l
  curLevelNum: -> @constructor.getLevelNum @level
  doesThisLevelApply: (l) -> @curLevelNum() <= @constructor.getLevelNum(l)

  # Always log, regardless of level. This is for terminal output not intended to be configured by
  # logging level.
  unconditionalLog: (...args) ->
    super.log ...args

  # Define the named logging methods (.log(), .warn(), ...) by extracting them from the superclass.
  trace: (...args) ->
    if @doesThisLevelApply 'trace'
      super ...args

  debug: (...args) ->
    if @doesThisLevelApply 'debug'
      super ...args

  info: (...args) ->
    if @doesThisLevelApply 'info'
      super ...args

  log: (...args) ->
    if @doesThisLevelApply 'log'
      super ...args

  warn: (...args) ->
    if @doesThisLevelApply 'warn'
      super ...args

  error: (...args) ->
    if @doesThisLevelApply 'error'
      super ...args

  # Call .dir(), but filtering by configured level.
  dirLevel: (level, ...args) ->
    if @doesThisLevelApply level
      super.dir ...args

  # We want to be able to call .dir() as normal, but we also want to be able to call .dir.log() to
  # explicitly set the logging level for .dir().
  Object.defineProperty @::, 'dir',
    configurable: yes
    get: ->
      # By default, .dir() uses the 'log' level.
      dir = (...args) -> @dirLevel 'log', ...args
      Object.defineProperties dir, Object.fromEntries do => for k in @constructor.LEVELS
        f = do (k) => (...args) => @dirLevel k, ...args
        [k,
         enumerable: yes
         writable: yes
         configurable: yes
         value: Object.defineProperty f, 'name',
           configurable: yes
           value: k]
    # We wouldn't normally have to set this, but Console does some wonky prototype munging:
    # https://github.com/nodejs/node/blob/17fae65c72321659390c4cbcd9ddaf248accb953/lib/internal/console/constructor.js#L145-L147
    set: (dir) -> # ignore

  @stdio: ({
    stdout = process.stdout,
    stderr = process.stderr,
    ...opts,
  } = {}) => new @ {
    stdout,
    stderr,
    ...opts
  }


exports.setupConsole = ({level, useColors}) ->
  if global.cakeConsole?
    return global.cakeConsole

  opts = {level}
  unless useColors
    opts.colorMode = no
  global.console = global.cakeConsole = cakeConsole = CakeConsole.stdio opts
  console.debug "log level = #{level}"
  cakeConsole
