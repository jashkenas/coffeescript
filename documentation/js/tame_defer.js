var dns, err, host, ip, __tame_deferrals, _i, _len, _next, _ref, _while,
  _this = this;

__tame_k = function() {};

dns = require('dns');

_ref = ['yahoo.com', 'google.com', 'nytimes.com'];
_len = _ref.length;
_i = 0;
_while = function(__tame_k) {
  var _break, _continue;
  _break = __tame_k;
  _continue = function() {
    ++_i;
    return _while(__tame_k);
  };
  _next = _continue;
  if (_i < _len) {
    host = _ref[_i];
    (function(__tame_k) {
      __tame_deferrals = new tame.Deferrals(__tame_k);
      dns.resolve(host, "A", __tame_deferrals.defer({
        assign_fn: (function() {
          return function() {
            err = arguments[0];
            return ip = arguments[1];
          };
        })()
      }));
      __tame_deferrals._fulfill();
    })(function() {
      return _next(err ? console.log("Error for " + host + ": " + err) : console.log("Resolved  " + host + " -> " + ip));
    });
  } else {
    return _break();
  }
};
_while(__tame_k);
