# Create an OptionParser with a list of valid options.
op: exports.OptionParser: (rules, banner) ->
  @banner:        banner or 'Usage: [Options]'
  @options_title: 'Available options:'
  @rules:         build_rules(rules)
  this

# Parse the argument array, calling defined callbacks, returning the remaining non-option arguments.
op::parse: (args) ->
  options: {arguments: []}
  args:   args.concat []
  while (arg: args.shift())
    is_option: false
    for rule in @rules
      if rule.letter is arg or rule.flag is arg
        options[rule.name]: if rule.argument then args.shift() else true
        is_option: true
        break
    options.arguments.push arg unless is_option
  options

# Return the help text for this OptionParser, for --help and such.
op::help: ->
  longest: 0
  has_shorts: false
  lines: [@banner, '', @options_title]
  for rule in @rules
    has_shorts: true if rule.letter
    longest: rule.flag.length if rule.flag.length > longest
  for rule in @rules
    if has_shorts
      text: if rule.letter then spaces(2) + rule.letter + ', ' else spaces(6)
    text += spaces(longest, rule.flag) + spaces(3)
    text += rule.description
    lines.push text
  lines.join('\n')

# Private:

# Regex matchers for option flags.
LONG_FLAG:  /^(--[\w\-]+)/
SHORT_FLAG: /^(-\w+)/
OPTIONAL:   /\[(.+)\]/

# Build rules from a list of valid switch tuples in the form:
# [letter-flag, long-flag, help], or [long-flag, help].
build_rules: (rules) ->
  for tuple in rules
    tuple.unshift(null) if tuple.length < 3
    build_rule(tuple...)

# Build a rule from a short-letter-flag, long-form-flag, and help text.
build_rule: (letter, flag, description) ->
  match: flag.match(OPTIONAL)
  flag:  flag.match(LONG_FLAG)[1]
  {
    name:         flag.substr(2)
    letter:       letter
    flag:         flag
    description:  description
    argument:     !!(match and match[1])
  }

# Space-pad a string with the specified number of characters.
spaces: (num, text) ->
  builder: []
  if text
    return text if text.length >= num
    num -= text.length
    builder.push text
  while num -= 1 then builder.push ' '
  builder.join ''
