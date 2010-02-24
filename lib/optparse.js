(function(){
  var LONG_FLAG, OPTIONAL, SHORT_FLAG, build_rule, build_rules, op, spaces;
  // Create an OptionParser with a list of valid options.
  op = (exports.OptionParser = function OptionParser(rules, banner) {
    this.banner = banner || 'Usage: [Options]';
    this.options_title = 'Available options:';
    this.rules = build_rules(rules);
    return this;
  });
  // Parse the argument array, calling defined callbacks, returning the remaining non-option arguments.
  op.prototype.parse = function parse(args) {
    var _a, _b, arg, is_option, options, rule;
    arguments = Array.prototype.slice.call(arguments, 0);
    options = {
      arguments: []
    };
    args = args.concat([]);
    while (((arg = args.shift()))) {
      is_option = false;
      _a = this.rules;
      for (_b = 0; _b < _a.length; _b++) {
        rule = _a[_b];
        if (rule.letter === arg || rule.flag === arg) {
          options[rule.name] = rule.argument ? args.shift() : true;
          is_option = true;
          break;
        }
      }
      if (!(is_option)) {
        options.arguments.push(arg);
      }
    }
    return options;
  };
  // Return the help text for this OptionParser, for --help and such.
  op.prototype.help = function help() {
    var _a, _b, _c, _d, has_shorts, lines, longest, rule, text;
    longest = 0;
    has_shorts = false;
    lines = [this.banner, '', this.options_title];
    _a = this.rules;
    for (_b = 0; _b < _a.length; _b++) {
      rule = _a[_b];
      if (rule.letter) {
        has_shorts = true;
      }
      if (rule.flag.length > longest) {
        longest = rule.flag.length;
      }
    }
    _c = this.rules;
    for (_d = 0; _d < _c.length; _d++) {
      rule = _c[_d];
      has_shorts ? (text = rule.letter ? spaces(2) + rule.letter + ', ' : spaces(6)) : null;
      text += spaces(longest, rule.flag) + spaces(3);
      text += rule.description;
      lines.push(text);
    }
    return lines.join('\n');
  };
  // Private:
  // Regex matchers for option flags.
  LONG_FLAG = /^(--[\w\-]+)/;
  SHORT_FLAG = /^(-\w+)/;
  OPTIONAL = /\[(.+)\]/;
  // Build rules from a list of valid switch tuples in the form:
  // [letter-flag, long-flag, help], or [long-flag, help].
  build_rules = function build_rules(rules) {
    var _a, _b, _c, tuple;
    _a = []; _b = rules;
    for (_c = 0; _c < _b.length; _c++) {
      tuple = _b[_c];
      _a.push((function() {
        if (tuple.length < 3) {
          tuple.unshift(null);
        }
        return build_rule.apply(this, tuple);
      }).call(this));
    }
    return _a;
  };
  // Build a rule from a short-letter-flag, long-form-flag, and help text.
  build_rule = function build_rule(letter, flag, description) {
    var match;
    match = flag.match(OPTIONAL);
    flag = flag.match(LONG_FLAG)[1];
    return {
      name: flag.substr(2),
      letter: letter,
      flag: flag,
      description: description,
      argument: !!(match && match[1])
    };
  };
  // Space-pad a string with the specified number of characters.
  spaces = function spaces(num, text) {
    var builder;
    builder = [];
    if (text) {
      if (text.length >= num) {
        return text;
      }
      num -= text.length;
      builder.push(text);
    }
    while (num -= 1) {
      builder.push(' ');
    }
    return builder.join('');
  };
})();