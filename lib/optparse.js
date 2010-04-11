(function(){
  var LONG_FLAG, MULTI_FLAG, OPTIONAL, OptionParser, SHORT_FLAG, build_rule, build_rules, normalize_arguments;
  // A simple **OptionParser** class to parse option flags from the command-line.
  // Use it like so:
  //     parser:  new OptionParser switches, help_banner
  //     options: parser.parse process.argv
  exports.OptionParser = (function() {
    OptionParser = function OptionParser(rules, banner) {
      this.banner = banner;
      this.rules = build_rules(rules);
      return this;
    };
    // Initialize with a list of valid options, in the form:
    //     [short-flag, long-flag, description]
    // Along with an an optional banner for the usage help.
    // Parse the list of arguments, populating an `options` object with all of the
    // specified options, and returning it. `options.arguments` will be an array
    // containing the remaning non-option arguments. This is a simpler API than
    // many option parsers that allow you to attach callback actions for every
    // flag. Instead, you're responsible for interpreting the options object.
    OptionParser.prototype.parse = function parse(args) {
      var _a, _b, _c, arg, is_option, matched_rule, options, rule;
      options = {
        arguments: []
      };
      args = normalize_arguments(args);
      while ((arg = args.shift())) {
        is_option = !!(arg.match(LONG_FLAG) || arg.match(SHORT_FLAG));
        matched_rule = false;
        _b = this.rules;
        for (_a = 0, _c = _b.length; _a < _c; _a++) {
          rule = _b[_a];
          if (rule.short_flag === arg || rule.long_flag === arg) {
            options[rule.name] = rule.has_argument ? args.shift() : true;
            matched_rule = true;
            break;
          }
        }
        if (is_option && !matched_rule) {
          throw new Error(("unrecognized option: " + arg));
        }
        if (!(is_option)) {
          options.arguments.push(arg);
        }
      }
      return options;
    };
    // Return the help text for this **OptionParser**, listing and describing all
    // of the valid options, for `--help` and such.
    OptionParser.prototype.help = function help() {
      var _a, _b, _c, _d, _e, _f, _g, i, let_part, lines, rule, spaces;
      lines = ['Available options:'];
      if (this.banner) {
        lines.unshift(("" + this.banner + "\n"));
      }
      _b = this.rules;
      for (_a = 0, _c = _b.length; _a < _c; _a++) {
        rule = _b[_a];
        spaces = 15 - rule.long_flag.length;
        spaces = spaces > 0 ? (function() {
          _d = []; _f = 0; _g = spaces;
          for (_e = 0, i = _f; (_f <= _g ? i <= _g : i >= _g); (_f <= _g ? i += 1 : i -= 1), _e++) {
            _d.push(' ');
          }
          return _d;
        })().join('') : '';
        let_part = rule.short_flag ? rule.short_flag + ', ' : '    ';
        lines.push(("  " + let_part + rule.long_flag + spaces + rule.description));
      }
      return "\n" + (lines.join('\n')) + "\n";
    };
    return OptionParser;
  })();
  // Helpers
  // -------
  // Regex matchers for option flags.
  LONG_FLAG = /^(--\w[\w\-]+)/;
  SHORT_FLAG = /^(-\w)/;
  MULTI_FLAG = /^-(\w{2,})/;
  OPTIONAL = /\[(.+)\]/;
  // Build and return the list of option rules. If the optional *short-flag* is
  // unspecified, leave it out by padding with `null`.
  build_rules = function build_rules(rules) {
    var _a, _b, _c, _d, tuple;
    _a = []; _c = rules;
    for (_b = 0, _d = _c.length; _b < _d; _b++) {
      tuple = _c[_b];
      _a.push((function() {
        if (tuple.length < 3) {
          tuple.unshift(null);
        }
        return build_rule.apply(this, tuple);
      })());
    }
    return _a;
  };
  // Build a rule from a `-o` short flag, a `--output [DIR]` long flag, and the
  // description of what the option does.
  build_rule = function build_rule(short_flag, long_flag, description) {
    var match;
    match = long_flag.match(OPTIONAL);
    long_flag = long_flag.match(LONG_FLAG)[1];
    return {
      name: long_flag.substr(2),
      short_flag: short_flag,
      long_flag: long_flag,
      description: description,
      has_argument: !!(match && match[1])
    };
  };
  // Normalize arguments by expanding merged flags into multiple flags. This allows
  // you to have `-wl` be the same as `--watch --lint`.
  normalize_arguments = function normalize_arguments(args) {
    var _a, _b, _c, _d, _e, _f, arg, l, match, result;
    args = args.slice(0);
    result = [];
    _b = args;
    for (_a = 0, _c = _b.length; _a < _c; _a++) {
      arg = _b[_a];
      if ((match = arg.match(MULTI_FLAG))) {
        _e = match[1].split('');
        for (_d = 0, _f = _e.length; _d < _f; _d++) {
          l = _e[_d];
          result.push('-' + l);
        }
      } else {
        result.push(arg);
      }
    }
    return result;
  };
})();
