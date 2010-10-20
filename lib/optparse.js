(function() {
  var LONG_FLAG, MULTI_FLAG, OPTIONAL, OptionParser, SHORT_FLAG, buildRule, buildRules, normalizeArguments;
  exports.OptionParser = (function() {
    OptionParser = (function() {
      function OptionParser(rules, banner) {
        this.banner = banner;
        this.rules = buildRules(rules);
        return this;
      };
      return OptionParser;
    })();
    OptionParser.prototype.parse = function(args) {
      var _i, _len, _len2, _ref, arg, i, isOption, matchedRule, options, rule, value;
      options = {
        arguments: []
      };
      args = normalizeArguments(args);
      for (i = 0, _len = args.length; i < _len; i++) {
        arg = args[i];
        isOption = !!(arg.match(LONG_FLAG) || arg.match(SHORT_FLAG));
        matchedRule = false;
        for (_i = 0, _len2 = (_ref = this.rules).length; _i < _len2; _i++) {
          rule = _ref[_i];
          if (rule.shortFlag === arg || rule.longFlag === arg) {
            value = rule.hasArgument ? args[i += 1] : true;
            options[rule.name] = rule.isList ? (options[rule.name] || []).concat(value) : value;
            matchedRule = true;
            break;
          }
        }
        if (isOption && !matchedRule) {
          throw new Error("unrecognized option: " + arg);
        }
        if (!isOption) {
          options.arguments = args.slice(i);
          break;
        }
      }
      return options;
    };
    OptionParser.prototype.help = function() {
      var _i, _len, _ref, letPart, lines, rule, spaces;
      lines = ['Available options:'];
      if (this.banner) {
        lines.unshift("" + (this.banner) + "\n");
      }
      for (_i = 0, _len = (_ref = this.rules).length; _i < _len; _i++) {
        rule = _ref[_i];
        spaces = 15 - rule.longFlag.length;
        spaces = spaces > 0 ? Array(spaces + 1).join(' ') : '';
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
    var _i, _len, _result, tuple;
    _result = [];
    for (_i = 0, _len = rules.length; _i < _len; _i++) {
      tuple = rules[_i];
      _result.push((function() {
        if (tuple.length < 3) {
          tuple.unshift(null);
        }
        return buildRule.apply(buildRule, tuple);
      })());
    }
    return _result;
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
    var _i, _j, _len, _len2, _ref, arg, l, match, result;
    args = args.slice(0);
    result = [];
    for (_i = 0, _len = args.length; _i < _len; _i++) {
      arg = args[_i];
      if (match = arg.match(MULTI_FLAG)) {
        for (_j = 0, _len2 = (_ref = match[1].split('')).length; _j < _len2; _j++) {
          l = _ref[_j];
          result.push('-' + l);
        }
      } else {
        result.push(arg);
      }
    }
    return result;
  };
}).call(this);
