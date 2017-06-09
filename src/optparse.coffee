{repeat, isString} = require './helpers'

# A simple **OptionParser** class to parse option flags from the command-line.
# Use it like so:
#
#     parser  = new OptionParser switches, helpBanner
#     options = parser.parse process.argv
#
# The first non-option is considered to be the start of the file (and file
# option) list, and all subsequent arguments are left unparsed.
#
# The `coffee` command uses an instance of **OptionParser** to parse its
# command-line arguments in `src/command.coffee`.
exports.OptionParser = class OptionParser

  # Initialize with a list of valid options, in the form:
  #
  #     [short-flag, long-flag, description]
  #
  # Along with an an optional banner for the usage help.
  constructor: (ruleDecls, @banner) ->
    @rules = buildRules ruleDecls

  # Parse the list of arguments, populating an `options` object with all of the
  # specified options, and return it. Options after the first non-option
  # argument are treated as arguments. `options.arguments` will be an array
  # containing the remaining arguments. This is a simpler API than many option
  # parsers that allow you to attach callback actions for every flag. Instead,
  # you're responsible for interpreting the options object.
  parse: (args) ->
    argsLeft = args[..]
    options = {}

    while argsLeft.length > 0
      # The CS option parser is a little odd; options after the first
      # non-option argument are treated as non-option arguments themselves.
      # Executable scripts do not need to have a `--` at the end of the
      # shebang ("#!") line, and if they do, they won't work on Linux.
      # Normalize arguments by expanding merged flags into multiple
      # flags. This allows you to have `-wl` be the same as `--watch --lint`.
      # `flags` are objects of {multi, flag}, where `multi` contains the
      # original command-line argument which was split, if applicable.
      # If `arg` is not a string, then we have already processed it.
      arg = argsLeft.shift()
      unless isString arg then argsLeft.unshift arg
      else
        flags = parseMultiFlag(arg) ? parseSingleFlag(arg)
        if flags?
          argsLeft.unshift flags...
        else
          # This is a positional argument.
          # TODO: should we check these with `isCoffee`?
          argsLeft.unshift(arg) unless arg is '--'
          break

      [cur, rest...] = argsLeft
      {flag, multi} = cur
      rule = @rules.flagDict[flag]
      unless rule?
        # TODO: test all of this!
        msg = "unrecognized option: #{flag}"
        msg += " (in multi-flag '#{multi}')" if multi?
        throw new Error msg

      {hasArgument, isList, name} = rule
      unless hasArgument then options[name] = true
      else
        # We do not touch flag arguments at all, but we don't know which flags
        # need arguments until we get to this point, which is why we use a while
        # loop above.
        # TODO: test this!
        nextArg = argsLeft.shift()
        unless nextArg? then throw new Error "value required for
          '#{flag}', which was the last argument provided"
        if isList
          options[name] ?= []
          options[name].push nextArg
        else
          options[name] = nextArg

    options.arguments = argsLeft
    options

  # Return the help text for this **OptionParser**, listing and describing all
  # of the valid options, for `--help` and such.
  help: ->
    lines = []
    lines.unshift "#{@banner}\n" if @banner
    for rule in @rules
      spaces  = 15 - rule.longFlag.length
      spaces  = if spaces > 0 then repeat ' ', spaces else ''
      letPart = if rule.shortFlag then rule.shortFlag + ', ' else '    '
      lines.push '  ' + letPart + rule.longFlag + spaces + rule.description
    "\n#{ lines.join('\n') }\n"

# Helpers
# -------

# Regex matchers for option flags on the command line and their rules.
LONG_FLAG  = /^(--\w[\w\-]*)/
SHORT_FLAG = /^(-\w)$/
MULTI_FLAG = /^-(\w{2,})/
# Matches the long flag part of a rule for an option with an argument. Not
# applied to anything in process.argv.
OPTIONAL   = /\[(\w+(\*?))\]/

# Build and return the list of option rules. If the optional *short-flag* is
# unspecified, leave it out by padding with `null`.
buildRules = (ruleDecls) ->
  ruleList = for tuple in ruleDecls
    tuple.unshift null if tuple.length < 3
    buildRule tuple...
  flagDict = {}
  for rule in ruleList
    # shortFlag is null if not provided in the rule.
    for flag in [rule.shortFlag, rule.longFlag] when flag?
      prevRule = flagDict[flag]
      if prevRule?
        throw new Error "flag #{flag} for switch #{rule.name}
          was already declared for switch #{prevRule.name}"
      flagDict[flag] = rule

  {ruleList, flagDict}

# Build a rule from a `-o` short flag, a `--output [DIR]` long flag, and the
# description of what the option does.
buildRule = (shortFlag, longFlag, description) ->
  match     = longFlag.match(OPTIONAL)
  shortFlag = shortFlag?.match(SHORT_FLAG)[1]
  longFlag  = longFlag.match(LONG_FLAG)[1]
  {
    name:         longFlag.substr 2
    shortFlag:    shortFlag
    longFlag:     longFlag
    description:  description
    hasArgument:  !!(match and match[1])
    isList:       !!(match and match[2])
  }

parseSingleFlag = (arg) ->
  if ([LONG_FLAG, SHORT_FLAG].some (pat) -> arg.match(pat)?) then [flag: arg]
  else null

parseMultiFlag = (arg) ->
  arg.match(MULTI_FLAG)?[1]
    .split('')
    .map (flagName) ->
      multi: arg
      flag: "-#{flagName}"
