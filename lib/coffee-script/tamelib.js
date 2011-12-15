(function() {
  var Pipeliner, tame, tame_internals, __tame_k, _timeout,
    __slice = Array.prototype.slice;

  
  __tame_k = function() {};

  tame_internals = require('./tame');

  tame = tame_internals.runtime;

  _timeout = function(cb, t, res, tmp) {
    var arr, rv, which, __tame_deferrals,
      _this = this;
    rv = new tame.Rendezvous;
    tmp[0] = rv.id(true).__tame_deferrals.defer({
      assign_fn: (function() {
        return function() {
          return arr = __slice.call(arguments, 0);
        };
      })()
    });
    setTimeout(rv.id(false).__tame_deferrals.defer({}), t);
    (function(__tame_k) {
      __tame_deferrals = new tame.Deferrals(__tame_k);
      rv.wait(__tame_deferrals.defer({
        assign_fn: (function() {
          return function() {
            return which = arguments[0];
          };
        })()
      }));
      __tame_deferrals._fulfill();
    })(function() {
      if (res) res[0] = which;
      return cb.apply(null, arr);
    });
  };

  exports.timeout = function(cb, t, res) {
    var tmp;
    tmp = [];
    _timeout(cb, t, res, tmp);
    return tmp[0];
  };

  exports.Pipeliner = Pipeliner = (function() {

    function Pipeliner(window, delay) {
      this.window = window || 1;
      this.delay = delay || 0;
      this.queue = [];
      this.n_out = 0;
      this.cb = null;
      this[tame_internals["const"].deferrals] = this;
      this["defer"] = this._defer;
    }

    Pipeliner.prototype.waitInQueue = function(cb) {
      var __tame_deferrals, _while,
        _this = this;
      (function(__tame_k) {
        _while = function(__tame_k) {
          var _break, _continue;
          _break = __tame_k;
          _continue = function() {
            return _while(__tame_k);
          };
          if (_this.n_out > _this.window) {
            (function(__tame_k) {
              __tame_deferrals = new tame.Deferrals(__tame_k);
              _this.cb = __tame_deferrals.defer({});
              __tame_deferrals._fulfill();
            })(function() {
              return _continue();
            });
          } else {
            return _break();
          }
        };
        _while(__tame_k);
      })(function() {
        _this.n_out++;
        (function(__tame_k) {
          if (_this.delay) {
            (function(__tame_k) {
              __tame_deferrals = new tame.Deferrals(__tame_k);
              setTimeout(__tame_deferrals.defer({}), _this.delay);
              __tame_deferrals._fulfill();
            })(function() {
              return __tame_k();
            });
          } else {
            return __tame_k();
          }
        })(function() {
          return cb();
        });
      });
    };

    Pipeliner.prototype.__defer = function(out, deferArgs) {
      var tmp, voidCb, __tame_deferrals,
        _this = this;
      (function(__tame_k) {
        __tame_deferrals = new tame.Deferrals(__tame_k);
        voidCb = __tame_deferrals.defer({});
        out[0] = function() {
          var args, _ref;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          if ((_ref = deferArgs.assign_fn) != null) _ref.apply(null, args);
          return voidCb();
        };
        __tame_deferrals._fulfill();
      })(function() {
        _this.n_out--;
        if (_this.cb) {
          tmp = _this.cb;
          _this.cb = null;
          return tmp();
        }
      });
    };

    Pipeliner.prototype._defer = function(deferArgs) {
      var tmp;
      tmp = [];
      this.__defer(tmp, deferArgs);
      return tmp[0];
    };

    Pipeliner.prototype.flush = function(autocb) {
      var __tame_deferrals, _while,
        _this = this;
      __tame_k = autocb;
      _while = function(__tame_k) {
        var _break, _continue;
        _break = __tame_k;
        _continue = function() {
          return _while(__tame_k);
        };
        if (_this.n_out) {
          (function(__tame_k) {
            __tame_deferrals = new tame.Deferrals(__tame_k);
            _this.cb = __tame_deferrals.defer({});
            __tame_deferrals._fulfill();
          })(function() {
            return _continue();
          });
        } else {
          return _break();
        }
      };
      _while(__tame_k);
    };

    return Pipeliner;
  })();
}).call(this);
