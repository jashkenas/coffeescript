this.exports: this unless process?

exports.utilities: class utilities
  @key: (name) ->
    "__$name"

  @format: (key, tab) ->
    "${utilities.key(key)} = ${utilities.functions[key].replace(/\n/g, "\n$tab") or 'undefined'}"

  @dependencies: {
    bind:   ['slice']
  }

  @functions: {

    extend:   """
              function(child, parent) {
                var ctor = function(){ };
                ctor.prototype = parent.prototype;
                child.__superClass__ = parent.prototype;
                child.prototype = new ctor();
                child.prototype.constructor = child;
              }
              """

    bind:     """
              function(func, obj, args) {
                return function() {
                  return func.apply(obj || {}, args ? args.concat(${utilities.key('slice')}.call(arguments, 0)) : arguments);
                };
              }
              """

    range:    """
              function(array, from, to, exclusive) {
                return [
                  (from < 0 ? from + array.length : from || 0),
                  (to < 0 ? to + array.length : to || array.length) + (exclusive ? 0 : 1)
                ];
              }
              """

    hasProp:  'Object.prototype.hasOwnProperty'

    slice:    'Array.prototype.slice'
  }