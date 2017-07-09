{repeat} = require './helpers'

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
  # Along with an optional banner for the usage help.
  constructor: (ruleDeclarations, @banner) ->
    @rules = buildRules ruleDeclarations

  # Parse the list of arguments, populating an `options` object with all of the
  # specified options, and return it. Options after the first non-option
  # argument are treated as arguments. `options.arguments` will be an array
  # containing the remaining arguments. This is a simpler API than many option
  # parsers that allow you to attach callback actions for every flag. Instead,
  # you're responsible for interpreting the options object.
  parse: (args) ->
    # The CoffeeScript option parser is a little odd; options after the first
    # non-option argument are treated as non-option arguments themselves.
    # Optional arguments are normalized by expanding merged flags into multiple
    # flags. This allows you to have `-wl` be the same as `--watch --lint`.
    # Note that executable scripts with a shebang (`#!`) line should use the
    # line `#!/usr/bin/env coffee`, or `#!/absolute/path/to/coffee`, without a
    # `--` argument after, because that will fail on Linux (see #3946).
    {rules, positional} = normalizeArguments args, @rules.flagDict
    options = {}

    # The `argument` field is added to the rule instance non-destructively by
    # `normalizeArguments`.
    for {hasArgument, argument, isList, name} in rules
      if hasArgument
        if isList
          options[name] ?= []
          options[name].push argument
        else
          options[name] = argument
      else
        options[name] = true

    if positional[0] is '--'
      options.doubleDashed = yes
      positional = positional[1..]

    options.arguments = positional
    options

  # Return the help text for this **OptionParser**, listing and describing all
  # of the valid options, for `--help` and such.
  help: ->
    lines = []
    lines.unshift "#{@banner}\n" if @banner
    for rule in @rules.ruleList
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
buildRules = (ruleDeclarations) ->
  ruleList = for tuple in ruleDeclarations
    tuple.unshift null if tuple.length < 3
    buildRule tuple...
  flagDict = {}
  for rule in ruleList
    # `shortFlag` is null if not provided in the rule.
    for flag in [rule.shortFlag, rule.longFlag] when flag?
      if flagDict[flag]?
        throw new Error "flag #{flag} for switch #{rule.name}
          was already declared for switch #{flagDict[flag].name}"
      flagDict[flag] = rule

  {ruleList, flagDict}

# Build a rule from a `-o` short flag, a `--output [DIR]` long flag, and the
# description of what the option does.
buildRule = (shortFlag, longFlag, description) ->
  match     = longFlag.match(OPTIONAL)
  shortFlag = shortFlag?.match(SHORT_FLAG)[1]
  longFlag  = longFlag.match(LONG_FLAG)[1]
  {
    name:         longFlag.replace /^--/, ''
    shortFlag:    shortFlag
    longFlag:     longFlag
    description:  description
    hasArgument:  !!(match and match[1])
    isList:       !!(match and match[2])
  }

normalizeArguments = (args, flagDict) ->
  rules = []
  positional = []
  needsArgOpt = null
  for arg, argIndex in args
    # If the previous argument given to the script was an option that uses the
    # next command-line argument as its argument, create copy of the option’s
    # rule with an `argument` field.
    if needsArgOpt?
      withArg = Object.assign {}, needsArgOpt.rule, {argument: arg}
      rules.push withArg
      needsArgOpt = null
      continue

    multiFlags = arg.match(MULTI_FLAG)?[1]
      .split('')
      .map (flagName) -> "-#{flagName}"
    if multiFlags?
      multiOpts = multiFlags.map (flag) ->
        rule = flagDict[flag]
        unless rule?
          throw new Error "unrecognized option #{flag} in multi-flag #{arg}"
        {rule, flag}
      # Only the last flag in a multi-flag may have an argument.
      [innerOpts..., lastOpt] = multiOpts
      for {rule, flag} in innerOpts
        if rule.hasArgument
          throw new Error "cannot use option #{flag} in multi-flag #{arg} except
          as the last option, because it needs an argument"
        rules.push rule
      if lastOpt.rule.hasArgument
        needsArgOpt = lastOpt
      else
        rules.push lastOpt.rule
    else if ([LONG_FLAG, SHORT_FLAG].some (pat) -> arg.match(pat)?)
      singleRule = flagDict[arg]
      unless singleRule?
        throw new Error "unrecognized option #{arg}"
      if singleRule.hasArgument
        needsArgOpt = {rule: singleRule, flag: arg}
      else
        rules.push singleRule
    else
      # This is a positional argument.
      positional = args[argIndex..]
      break

  if needsArgOpt?
    throw new Error "value required for #{needsArgOpt.flag}, but it was the last
    argument provided"
  {rules, positional}
