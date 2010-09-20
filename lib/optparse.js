(function() {
  var LONG_FLAG, MULTI_FLAG, OPTIONAL, OptionParser, SHORT_FLAG, buildRule, buildRules, normalizeArguments;
  exports.OptionParser = (function() {
    OptionParser = function(rules, banner) {
      this.banner = banner;
      this.rules = buildRules(rules);
      return this;
    };
    OptionParser.prototype.parse = function(args) {
      var _cache, _cache2, _index, _length, _length2, arg, i, isOption, matchedRule, options, rule, value;
      options = {
        arguments: []
      };
      args = normalizeArguments(args);
      _cache = args;
      for (i = 0, _length = _cache.length; i < _length; i++) {
        arg = _cache[i];
        isOption = !!(arg.match(LONG_FLAG) || arg.match(SHORT_FLAG));
        matchedRule = false;
        _cache2 = this.rules;
        for (_index = 0, _length2 = _cache2.length; _index < _length2; _index++) {
          rule = _cache2[_index];
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
      var _cache, _index, _length, _result, i, letPart, lines, rule, spaces;
      lines = ['Available options:'];
      if (this.banner) {
        lines.unshift("" + (this.banner) + "\n");
      }
      _cache = this.rules;
      for (_index = 0, _length = _cache.length; _index < _length; _index++) {
        rule = _cache[_index];
        spaces = 15 - rule.longFlag.length;
        spaces = spaces > 0 ? (function() {
          _result = [];
          for (i = 0; (0 <= spaces ? i <= spaces : i >= spaces); (0 <= spaces ? i += 1 : i -= 1)) {
            _result.push(' ');
          }
          return _result;
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
    var _cache, _index, _length, _result, tuple;
    _result = []; _cache = rules;
    for (_index = 0, _length = _cache.length; _index < _length; _index++) {
      tuple = _cache[_index];
      _result.push((function() {
        if (tuple.length < 3) {
          tuple.unshift(null);
        }
        return buildRule.apply(this, tuple);
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
    var _cache, _cache2, _index, _index2, _length, _length2, arg, l, match, result;
    args = args.slice(0);
    result = [];
    _cache = args;
    for (_index = 0, _length = _cache.length; _index < _length; _index++) {
      arg = _cache[_index];
      if (match = arg.match(MULTI_FLAG)) {
        _cache2 = match[1].split('');
        for (_index2 = 0, _length2 = _cache2.length; _index2 < _length2; _index2++) {
          l = _cache2[_index2];
          result.push('-' + l);
        }
      } else {
        result.push(arg);
      }
    }
    return result;
  };
})();
