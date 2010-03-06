(function(){
  var LONG_FLAG, MULTI_FLAG, OPTIONAL, OptionParser, SHORT_FLAG, build_rule, build_rules, normalize_arguments;
  // Create an OptionParser with a list of valid options, in the form:
  //   [short-flag (optional), long-flag, description]
  // And an optional banner for the usage help.
  exports.OptionParser = (function() {
    OptionParser = function OptionParser(rules, banner) {
      this.banner = banner;
      this.rules = build_rules(rules);
      return this;
    };
    // Parse the argument array, populating an options object with all of the
    // specified options, and returning it. options.arguments will be an array
    // containing the remaning non-option arguments.
    OptionParser.prototype.parse = function parse(args) {
      var _a, _b, _c, arg, is_option, matched_rule, options, rule;
      arguments = Array.prototype.slice.call(arguments, 0);
      options = {
        arguments: []
      };
      args = normalize_arguments(args);
      while (arg = args.shift()) {
        is_option = !!(arg.match(LONG_FLAG) || arg.match(SHORT_FLAG));
        matched_rule = false;
        _a = this.rules;
        for (_b = 0, _c = _a.length; _b < _c; _b++) {
          rule = _a[_b];
          if (rule.letter === arg || rule.flag === arg) {
            options[rule.name] = rule.has_argument ? args.shift() : true;
            matched_rule = true;
            break;
          }
        }
        if (is_option && !matched_rule) {
          throw new Error("unrecognized option: " + arg);
        }
        if (!(is_option)) {
          options.arguments.push(arg);
        }
      }
      return options;
    };
    // Return the help text for this OptionParser, for --help and such.
    OptionParser.prototype.help = function help() {
      var _a, _b, _c, _d, _e, _f, _g, _h, i, let_part, lines, rule, spaces;
      lines = ['Available options:'];
      if (this.banner) {
        lines.unshift(this.banner + "\n");
      }
      _a = this.rules;
      for (_b = 0, _c = _a.length; _b < _c; _b++) {
        rule = _a[_b];
        spaces = 15 - rule.flag.length;
        spaces = spaces > 0 ? (function() {
          _d = []; _g = 0; _h = spaces;
          for (_f = 0, i = _g; (_g <= _h ? i <= _h : i >= _h); (_g <= _h ? i += 1 : i -= 1), _f++) {
            _d.push(' ');
          }
          return _d;
        }).call(this).join('') : '';
        let_part = rule.letter ? rule.letter + ', ' : '    ';
        lines.push("  " + let_part + (rule.flag) + spaces + (rule.description));
      }
      return "\n" + (lines.join('\n')) + "\n";
    };
    return OptionParser;
  }).call(this);
  // Regex matchers for option flags.
  LONG_FLAG = /^(--\w[\w\-]+)/;
  SHORT_FLAG = /^(-\w)/;
  MULTI_FLAG = /^-(\w{2,})/;
  OPTIONAL = /\[(.+)\]/;
  // Build rules from a list of valid switch tuples in the form:
  // [letter-flag, long-flag, help], or [long-flag, help].
  build_rules = function build_rules(rules) {
    var _a, _b, _c, _d, tuple;
    _a = []; _b = rules;
    for (_c = 0, _d = _b.length; _c < _d; _c++) {
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
      has_argument: !!(match && match[1])
    };
  };
  // Normalize arguments by expanding merged flags into multiple flags.
  normalize_arguments = function normalize_arguments(args) {
    var _a, _b, _c, _d, _e, _f, arg, l, match, result;
    args = args.slice(0);
    result = [];
    _a = args;
    for (_b = 0, _c = _a.length; _b < _c; _b++) {
      arg = _a[_b];
      if ((match = arg.match(MULTI_FLAG))) {
        _d = match[1].split('');
        for (_e = 0, _f = _d.length; _e < _f; _e++) {
          l = _d[_e];
          result.push('-' + l);
        }
      } else {
        result.push(arg);
      }
    }
    return result;
  };
})();
