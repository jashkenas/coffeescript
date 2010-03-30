# A simple **OptionParser** class to parse option flags from the command-line.
# Use it like so:
#
#     parser:  new OptionParser switches, help_banner
#     options: parser.parse process.argv
exports.OptionParser: class OptionParser

  # Initialize with a list of valid options, in the form:
  #
  #     [short-flag, long-flag, description]
  #
  # Along with an an optional banner for the usage help.
  constructor: (rules, banner) ->
    @banner:  banner
    @rules:   build_rules(rules)

  # Parse the list of arguments, populating an `options` object with all of the
  # specified options, and returning it. `options.arguments` will be an array
  # containing the remaning non-option arguments. This is a simpler API than
  # many option parsers that allow you to attach callback actions for every
  # flag. Instead, you're responsible for interpreting the options object.
  parse: (args) ->
    options: {arguments: []}
    args: normalize_arguments args
    while (arg: args.shift())
      is_option: !!(arg.match(LONG_FLAG) or arg.match(SHORT_FLAG))
      matched_rule: no
      for rule in @rules
        if rule.short_flag is arg or rule.long_flag is arg
          options[rule.name]: if rule.has_argument then args.shift() else true
          matched_rule: yes
          break
      throw new Error "unrecognized option: $arg" if is_option and not matched_rule
      options.arguments.push arg unless is_option
    options

  # Return the help text for this **OptionParser**, listing and describing all
  # of the valid options, for `--help` and such.
  help: ->
    lines: ['Available options:']
    lines.unshift "$@banner\n" if @banner
    for rule in @rules
      spaces:   15 - rule.long_flag.length
      spaces:   if spaces > 0 then (' ' for i in [0..spaces]).join('') else ''
      let_part: if rule.short_flag then rule.short_flag + ', ' else '    '
      lines.push "  $let_part${rule.long_flag}$spaces${rule.description}"
    "\n${ lines.join('\n') }\n"

# Helpers
# -------

# Regex matchers for option flags.
LONG_FLAG:  /^(--\w[\w\-]+)/
SHORT_FLAG: /^(-\w)/
MULTI_FLAG: /^-(\w{2,})/
OPTIONAL:   /\[(.+)\]/

# Build and return the list of option rules. If the optional *short-flag* is
# unspecified, leave it out by padding with `null`.
build_rules: (rules) ->
  for tuple in rules
    tuple.unshift null if tuple.length < 3
    build_rule tuple...

# Build a rule from a `-o` short flag, a `--output [DIR]` long flag, and the
# description of what the option does.
build_rule: (short_flag, long_flag, description) ->
  match:      long_flag.match(OPTIONAL)
  long_flag:  long_flag.match(LONG_FLAG)[1]
  {
    name:         long_flag.substr 2
    short_flag:   short_flag
    long_flag:    long_flag
    description:  description
    has_argument: !!(match and match[1])
  }

# Normalize arguments by expanding merged flags into multiple flags. This allows
# you to have `-wl` be the same as `--watch --lint`.
normalize_arguments: (args) ->
  args: args.slice 0
  result: []
  for arg in args
    if match: arg.match MULTI_FLAG
      result.push '-' + l for l in match[1].split ''
    else
      result.push arg
  result
