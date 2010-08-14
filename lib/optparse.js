(function() {
  var LONG_FLAG, MULTI_FLAG, OPTIONAL, OptionParser, SHORT_FLAG, buildRule, buildRules, normalizeArguments;
  exports.OptionParser = (function() {
    OptionParser = function(rules, banner) {
      this.banner = banner;
      this.rules = buildRules(rules);
      return this;
    };
    OptionParser.prototype.parse = function(args) {
      var _a, _b, _c, _d, _e, arg, i, isOption, matchedRule, options, rule, value;
      options = {
        arguments: []
      };
      args = normalizeArguments(args);
      _a = args;
      for (i = 0, _b = _a.length; i < _b; i++) {
        arg = _a[i];
        isOption = !!(arg.match(LONG_FLAG) || arg.match(SHORT_FLAG));
        matchedRule = false;
        _d = this.rules;
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          rule = _d[_c];
          if (rule.shortFlag === arg || rule.longFlag === arg) {
            value = rule.hasArgument ? args[i += 1] : true;
            options[rule.name] = rule.isList ? (options[rule.name] || []).concat(value) : value;
            matchedRule = true;
            break;
          }
        }
        if (isOption && !matchedRule) {
          throw new Error("unrecognized option: " + (arg));
        }
        if (!isOption) {
          options.arguments = args.slice(i, args.length);
          break;
        }
      }
      return options;
    };
    OptionParser.prototype.help = function() {
      var _a, _b, _c, _d, i, letPart, lines, rule, spaces;
      lines = ['Available options:'];
      if (this.banner) {
        lines.unshift("" + (this.banner) + "\n");
      }
      _b = this.rules;
      for (_a = 0, _c = _b.length; _a < _c; _a++) {
        rule = _b[_a];
        spaces = 15 - rule.longFlag.length;
        spaces = spaces > 0 ? (function() {
          _d = [];
          for (i = 0; (0 <= spaces ? i <= spaces : i >= spaces); (0 <= spaces ? i += 1 : i -= 1)) {
            _d.push(' ');
          }
          return _d;
        })().join('') : '';
        letPart = rule.shortFlag ? rule.shortFlag + ', ' : '    ';
        lines.push('  ' + letPart + rule.longFlag + spaces + rule.description);
      }
      return "\n" + (lines.join('\n')) + "\n";
    };
    return OptionParser;
  })();
  LONG_FLAG = /^(--\w[\w\-]+)/;
  SHORT_FLAG = /^(-\w)/;
  MULTI_FLAG = /^-(\w{2,})/;
  OPTIONAL = /\[(\w+(\*?))\]/;
  buildRules = function(rules) {
    var _a, _b, _c, _d, tuple;
    _a = []; _c = rules;
    for (_b = 0, _d = _c.length; _b < _d; _b++) {
      tuple = _c[_b];
      _a.push((function() {
        if (tuple.length < 3) {
          tuple.unshift(null);
        }
        return buildRule.apply(this, tuple);
      })());
    }
    return _a;
  };
  buildRule = function(shortFlag, longFlag, description, options) {
    var match;
    match = longFlag.match(OPTIONAL);
    longFlag = longFlag.match(LONG_FLAG)[1];
    options || (options = {});
    return {
      name: longFlag.substr(2),
      shortFlag: shortFlag,
      longFlag: longFlag,
      description: description,
      hasArgument: !!(match && match[1]),
      isList: !!(match && match[2])
    };
  };
  normalizeArguments = function(args) {
    var _a, _b, _c, _d, _e, _f, arg, l, match, result;
    args = args.slice(0);
    result = [];
    _b = args;
    for (_a = 0, _c = _b.length; _a < _c; _a++) {
      arg = _b[_a];
      if (match = arg.match(MULTI_FLAG)) {
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
