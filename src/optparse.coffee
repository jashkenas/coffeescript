# Create an OptionParser with a list of valid options, in the form:
#   [short-flag (optional), long-flag, description]
# And an optional banner for the usage help.
op: exports.OptionParser: (rules, banner) ->
  @banner:  banner or 'Usage: [Options]'
  @rules:   build_rules(rules)
  this

# Parse the argument array, populating an options object with all of the
# specified options, and returning it. options.arguments will be an array
# containing the remaning non-option arguments.
op::parse: (args) ->
  options: {arguments: []}
  args: args.slice 0
  while arg: args.shift()
    is_option: !!(arg.match(LONG_FLAG) or arg.match(SHORT_FLAG))
    matched_rule: no
    for rule in @rules
      if rule.letter is arg or rule.flag is arg
        options[rule.name]: if rule.has_argument then args.shift() else true
        matched_rule: yes
        break
    throw new Error "unrecognized option: " + arg if is_option and not matched_rule
    options.arguments.push arg unless is_option
  options

# Return the help text for this OptionParser, for --help and such.
op::help: ->
  lines: [@banner, '', 'Available options:']
  for rule in @rules
    spaces:   15 - rule.flag.length
    spaces:   if spaces > 0 then (' ' for i in [0..spaces]).join('') else ''
    let_part: if rule.letter then rule.letter + ', ' else '    '
    lines.push '  ' + let_part + rule.flag + spaces + rule.description
  lines.join('\n')

# Regex matchers for option flags.
LONG_FLAG:  /^(--\w[\w\-]+)/
SHORT_FLAG: /^(-\w+)/
OPTIONAL:   /\[(.+)\]/

# Build rules from a list of valid switch tuples in the form:
# [letter-flag, long-flag, help], or [long-flag, help].
build_rules: (rules) ->
  for tuple in rules
    tuple.unshift null if tuple.length < 3
    build_rule tuple...

# Build a rule from a short-letter-flag, long-form-flag, and help text.
build_rule: (letter, flag, description) ->
  match: flag.match(OPTIONAL)
  flag:  flag.match(LONG_FLAG)[1]
  {
    name:         flag.substr 2
    letter:       letter
    flag:         flag
    description:  description
    has_argument: !!(match and match[1])
  }
