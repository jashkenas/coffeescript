# A simple **OptionParser** class to parse option flags from the command-line.
# Use it like so:
#
#     parser  = new OptionParser switches, helpBanner
#     options = parser.parse process.argv
#
# The first non-option is considered to be the start of the file (and file
# option) list, and all subsequent arguments are left unparsed.
exports.OptionParser = class OptionParser

  # Initialize with a list of valid options, in the form:
  #
  #     [short-flag, long-flag, description]
  #
  # Along with an an optional banner for the usage help.
  constructor: (rules, @banner) ->
    @rules = buildRules rules

  # Parse the list of arguments, populating an `options` object with all of the
  # specified options, and return it. Options after the first non-option
  # argument are treated as arguments. `options.arguments` will be an array
  # containing the remaining arguments. This is a simpler API than many option
  # parsers that allow you to attach callback actions for every flag. Instead,
  # you're responsible for interpreting the options object.
  parse: (args) ->
    options = arguments: []
    skippingArgument = no
    originalArgs = args
    args = normalizeArguments args
    for arg, i in args
      if skippingArgument
        skippingArgument = no
        continue
      if arg is '--'
        pos = originalArgs.indexOf '--'
        options.arguments = options.arguments.concat originalArgs[(pos + 1)..]
        break
      isOption = !!(arg.match(LONG_FLAG) or arg.match(SHORT_FLAG))
      # the CS option parser is a little odd; options after the first
      # non-option argument are treated as non-option arguments themselves
      seenNonOptionArg = options.arguments.length > 0
      unless seenNonOptionArg
        matchedRule = no
        for rule in @rules
          if rule.shortFlag is arg or rule.longFlag is arg
            value = true
            if rule.hasArgument
              skippingArgument = yes
              value = args[i + 1]
            options[rule.name] = if rule.isList then (options[rule.name] or []).concat value else value
            matchedRule = yes
            break
        throw new Error "unrecognized option: #{arg}" if isOption and not matchedRule
      if seenNonOptionArg or not isOption
        options.arguments.push arg
    options

  # Return the help text for this **OptionParser**, listing and describing all
  # of the valid options, for `--help` and such.
  help: ->
    lines = []
    lines.unshift "#{@banner}\n" if @banner
    for rule in @rules
      spaces  = 15 - rule.longFlag.length
      spaces  = if spaces > 0 then Array(spaces + 1).join(' ') else ''
      letPart = if rule.shortFlag then rule.shortFlag + ', ' else '    '
      lines.push '  ' + letPart + rule.longFlag + spaces + rule.description
    "\n#{ lines.join('\n') }\n"

# Helpers
# -------

# Regex matchers for option flags.
LONG_FLAG  = /^(--\w[\w\-]*)/
SHORT_FLAG = /^(-\w)$/
MULTI_FLAG = /^-(\w{2,})/
OPTIONAL   = /\[(\w+(\*?))\]/

# Build and return the list of option rules. If the optional *short-flag* is
# unspecified, leave it out by padding with `null`.
buildRules = (rules) ->
  for tuple in rules
    tuple.unshift null if tuple.length < 3
    buildRule tuple...

# Build a rule from a `-o` short flag, a `--output [DIR]` long flag, and the
# description of what the option does.
buildRule = (shortFlag, longFlag, description, options = {}) ->
  match     = longFlag.match(OPTIONAL)
  longFlag  = longFlag.match(LONG_FLAG)[1]
  {
    name:         longFlag.substr 2
    shortFlag:    shortFlag
    longFlag:     longFlag
    description:  description
    hasArgument:  !!(match and match[1])
    isList:       !!(match and match[2])
  }

# Normalize arguments by expanding merged flags into multiple flags. This allows
# you to have `-wl` be the same as `--watch --lint`.
normalizeArguments = (args) ->
  args = args[..]
  result = []
  for arg in args
    if match = arg.match MULTI_FLAG
      result.push '-' + l for l in match[1].split ''
    else
      result.push arg
  result
