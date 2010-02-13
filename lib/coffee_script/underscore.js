(function(){
  var _, breaker, idCounter, previousUnderscore, result, root, slice, unshift, wrapper;
  var __hasProp = Object.prototype.hasOwnProperty;
  // Underscore.coffee
  // (c) 2010 Jeremy Ashkenas, DocumentCloud Inc.
  // Underscore is freely distributable under the terms of the MIT license.
  // Portions of Underscore are inspired by or borrowed from Prototype.js,
  // Oliver Steele's Functional, and John Resig's Micro-Templating.
  // For all details and documentation:
  // http://documentcloud.github.com/underscore/
  // ------------------------- Baseline setup ---------------------------------
  // Establish the root object, "window" in the browser, or "global" on the server.
  root = this;
  // Save the previous value of the "_" variable.
  previousUnderscore = root._;
  // If Underscore is called as a function, it returns a wrapped object that
  // can be used OO-style. This wrapper holds altered versions of all the
  // underscore functions. Wrapped objects may be chained.
  wrapper = function wrapper(obj) {
    this._wrapped = obj;
    return this;
  };
  // Establish the object that gets thrown to break out of a loop iteration.
  breaker = typeof (StopIteration) === 'undefined' ? '__break__' : StopIteration;
  // Create a safe reference to the Underscore object forreference below.
  _ = (root._ = function _(obj) {
    return new wrapper(obj);
  });
  // Export the Underscore object for CommonJS.
  typeof (exports) !== 'undefined' ? (exports._ = _) : null;
  // Create quick reference variables for speed access to core prototypes.
  slice = Array.prototype.slice;
  unshift = Array.prototype.unshift;
  toString = Object.prototype.toString;
  hasOwnProperty = Object.prototype.hasOwnProperty;
  propertyIsEnumerable = Object.prototype.propertyIsEnumerable;
  // Current version.
  _.VERSION = '0.5.8';
  // ------------------------ Collection Functions: ---------------------------
  // The cornerstone, an each implementation.
  // Handles objects implementing forEach, arrays, and raw objects.
  _.each = function each(obj, iterator, context) {
    var __a, __b, __c, __d, __e, __f, i, index, key, val;
    index = 0;
    try {
      if (obj.forEach) {
        return obj.forEach(iterator, context);
      }
      if (_.isNumber(obj.length)) {
        __a = []; __d = 0; __e = obj.length;
        for (__c=0, i=__d; (__d <= __e ? i < __e : i > __e); (__d <= __e ? i += 1 : i -= 1), __c++) {
          __a.push(iterator.call(context, obj[i], i, obj));
        }
        return __a;
      }
      __f = obj;
      for (key in __f) {
        val = __f[key];
        if (__hasProp.call(__f, key)) {
          iterator.call(context, val, key, obj);
        }
      }
    } catch (e) {
      if (e !== breaker) {
        throw e;
      }
    }
    return obj;
  };
  // Return the results of applying the iterator to each element. Use JavaScript
  // 1.6's version of map, if possible.
  _.map = function map(obj, iterator, context) {
    var results;
    if ((obj && _.isFunction(obj.map))) {
      return obj.map(iterator, context);
    }
    results = [];
    _.each(obj, function(value, index, list) {
      return results.push(iterator.call(context, value, index, list));
    });
    return results;
  };
  // Reduce builds up a single result from a list of values. Also known as
  // inject, or foldl. Uses JavaScript 1.8's version of reduce, if possible.
  _.reduce = function reduce(obj, memo, iterator, context) {
    if ((obj && _.isFunction(obj.reduce))) {
      return obj.reduce(_.bind(iterator, context), memo);
    }
    _.each(obj, function(value, index, list) {
      return memo = iterator.call(context, memo, value, index, list);
    });
    return memo;
  };
  // The right-associative version of reduce, also known as foldr. Uses
  // JavaScript 1.8's version of reduceRight, if available.
  _.reduceRight = function reduceRight(obj, memo, iterator, context) {
    if ((obj && _.isFunction(obj.reduceRight))) {
      return obj.reduceRight(_.bind(iterator, context), memo);
    }
    _.each(_.clone(_.toArray(obj)).reverse(), function(value, index) {
      return memo = iterator.call(context, memo, value, index, obj);
    });
    return memo;
  };
  // Return the first value which passes a truth test.
  _.detect = function detect(obj, iterator, context) {
    var result;
    result = null;
    _.each(obj, function(value, index, list) {
      if (iterator.call(context, value, index, list)) {
        result = value;
        return _.breakLoop();
      }
    });
    return result;
  };
  // Return all the elements that pass a truth test. Use JavaScript 1.6's
  // filter(), if it exists.
  _.select = function select(obj, iterator, context) {
    var results;
    if (obj && _.isFunction(obj.filter)) {
      return obj.filter(iterator, context);
    }
    results = [];
    _.each(obj, function(value, index, list) {
      if (iterator.call(context, value, index, list)) {
        return results.push(value);
      }
    });
    return results;
  };
  // Return all the elements for which a truth test fails.
  _.reject = function reject(obj, iterator, context) {
    var results;
    results = [];
    _.each(obj, function(value, index, list) {
      if (!iterator.call(context, value, index, list)) {
        return results.push(value);
      }
    });
    return results;
  };
  // Determine whether all of the elements match a truth test. Delegate to
  // JavaScript 1.6's every(), if it is present.
  _.all = function all(obj, iterator, context) {
    var result;
    iterator = iterator || _.identity;
    if (obj && _.isFunction(obj.every)) {
      return obj.every(iterator, context);
    }
    result = true;
    _.each(obj, function(value, index, list) {
      if (!(((result = result && iterator.call(context, value, index, list))))) {
        return _.breakLoop();
      }
    });
    return result;
  };
  // Determine if at least one element in the object matches a truth test. Use
  // JavaScript 1.6's some(), if it exists.
  _.any = function any(obj, iterator, context) {
    var result;
    iterator = iterator || _.identity;
    if (obj && _.isFunction(obj.some)) {
      return obj.some(iterator, context);
    }
    result = false;
    _.each(obj, function(value, index, list) {
      if (((result = iterator.call(context, value, index, list)))) {
        return _.breakLoop();
      }
    });
    return result;
  };
  // Determine if a given value is included in the array or object,
  // based on '==='.
  _.include = function include(obj, target) {
    var __a, key, val;
    if (obj && _.isFunction(obj.indexOf)) {
      return _.indexOf(obj, target) !== -1;
    }
    __a = obj;
    for (key in __a) {
      val = __a[key];
      if (__hasProp.call(__a, key)) {
        if (val === target) {
          return true;
        }
      }
    }
    return false;
  };
  // Invoke a method with arguments on every item in a collection.
  _.invoke = function invoke(obj, method) {
    var __a, __b, __c, args, val;
    var arguments = Array.prototype.slice.call(arguments, 0);
    args = _.rest(arguments, 2);
    __a = []; __b = obj;
    for (__c = 0; __c < __b.length; __c++) {
      val = __b[__c];
      __a.push((method ? val[method] : val).apply(val, args));
    }
    return __a;
  };
  // Convenience version of a common use case of map: fetching a property.
  _.pluck = function pluck(obj, key) {
    return _.map(obj, (function(val) {
      return val[key];
    }));
  };
  // Return the maximum item or (item-based computation).
  _.max = function max(obj, iterator, context) {
    var result;
    if (!iterator && _.isArray(obj)) {
      return Math.max.apply(Math, obj);
    }
    result = {
      computed: -Infinity
    };
    _.each(obj, function(value, index, list) {
      var computed;
      computed = iterator ? iterator.call(context, value, index, list) : value;
      return computed >= result.computed && ((result = {
        value: value,
        computed: computed
      }));
    });
    return result.value;
  };
  // Return the minimum element (or element-based computation).
  _.min = function min(obj, iterator, context) {
    var result;
    if (!iterator && _.isArray(obj)) {
      return Math.min.apply(Math, obj);
    }
    result = {
      computed: Infinity
    };
    _.each(obj, function(value, index, list) {
      var computed;
      computed = iterator ? iterator.call(context, value, index, list) : value;
      return computed < result.computed && ((result = {
        value: value,
        computed: computed
      }));
    });
    return result.value;
  };
  // Sort the object's values by a criteria produced by an iterator.
  _.sortBy = function sortBy(obj, iterator, context) {
    return _.pluck(((_.map(obj, function(value, index, list) {
      return {
        value: value,
        criteria: iterator.call(context, value, index, list)
      };
    })).sort(function(left, right) {
      var a, b;
      a = left.criteria;
      b = right.criteria;
      if (a < b) {
        return -1;
      } else if (a > b) {
        return 1;
      } else {
        return 0;
      }
    })), 'value');
  };
  // Use a comparator function to figure out at what index an object should
  // be inserted so as to maintain order. Uses binary search.
  _.sortedIndex = function sortedIndex(array, obj, iterator) {
    var high, low, mid;
    iterator = iterator || _.identity;
    low = 0;
    high = array.length;
    while (low < high) {
      mid = (low + high) >> 1;
      iterator(array[mid]) < iterator(obj) ? (low = mid + 1) : (high = mid);
    }
    return low;
  };
  // Convert anything iterable into a real, live array.
  _.toArray = function toArray(iterable) {
    if ((!iterable)) {
      return [];
    }
    if ((iterable.toArray)) {
      return iterable.toArray();
    }
    if ((_.isArray(iterable))) {
      return iterable;
    }
    if ((_.isArguments(iterable))) {
      return slice.call(iterable);
    }
    return _.values(iterable);
  };
  // Return the number of elements in an object.
  _.size = function size(obj) {
    return _.toArray(obj).length;
  };
  // -------------------------- Array Functions: ------------------------------
  // Get the first element of an array. Passing "n" will return the first N
  // values in the array. Aliased as "head". The "guard" check allows it to work
  // with _.map.
  _.first = function first(array, n, guard) {
    return n && !guard ? slice.call(array, 0, n) : array[0];
  };
  // Returns everything but the first entry of the array. Aliased as "tail".
  // Especially useful on the arguments object. Passing an "index" will return
  // the rest of the values in the array from that index onward. The "guard"
  // check allows it to work with _.map.
  _.rest = function rest(array, index, guard) {
    return slice.call(array, _.isUndefined(index) || guard ? 1 : index);
  };
  // Get the last element of an array.
  _.last = function last(array) {
    return array[array.length - 1];
  };
  // Trim out all falsy values from an array.
  _.compact = function compact(array) {
    var __a, __b, __c, __d, __e, i;
    __a = []; __d = 0; __e = array.length;
    for (__c=0, i=__d; (__d <= __e ? i < __e : i > __e); (__d <= __e ? i += 1 : i -= 1), __c++) {
      if (array[i]) {
        __a.push(array[i]);
      }
    }
    return __a;
  };
  // Return a completely flattened version of an array.
  _.flatten = function flatten(array) {
    return _.reduce(array, [], function(memo, value) {
      if (_.isArray(value)) {
        return memo.concat(_.flatten(value));
      }
      memo.push(value);
      return memo;
    });
  };
  // Return a version of the array that does not contain the specified value(s).
  _.without = function without(array) {
    var __a, __b, __c, val, values;
    var arguments = Array.prototype.slice.call(arguments, 0);
    values = _.rest(arguments);
    __a = []; __b = _.toArray(array);
    for (__c = 0; __c < __b.length; __c++) {
      val = __b[__c];
      if (!_.include(values, val)) {
        __a.push(val);
      }
    }
    return __a;
  };
  // Produce a duplicate-free version of the array. If the array has already
  // been sorted, you have the option of using a faster algorithm.
  _.uniq = function uniq(array, isSorted) {
    var __a, el, i, memo;
    memo = [];
    __a = _.toArray(array);
    for (i = 0; i < __a.length; i++) {
      el = __a[i];
      if (i === 0 || (isSorted === true ? _.last(memo) !== el : !_.include(memo, el))) {
        memo.push(el);
      }
    }
    return memo;
  };
  // Produce an array that contains every item shared between all the
  // passed-in arrays.
  _.intersect = function intersect(array) {
    var rest;
    var arguments = Array.prototype.slice.call(arguments, 0);
    rest = _.rest(arguments);
    return _.select(_.uniq(array), function(item) {
      return _.all(rest, function(other) {
        return _.indexOf(other, item) >= 0;
      });
    });
  };
  // Zip together multiple lists into a single array -- elements that share
  // an index go together.
  _.zip = function zip() {
    var __a, __b, __c, __d, i, length, results;
    var arguments = Array.prototype.slice.call(arguments, 0);
    length = _.max(_.pluck(arguments, 'length'));
    results = new Array(length);
    __c = 0; __d = length;
    for (__b=0, i=__c; (__c <= __d ? i < __d : i > __d); (__c <= __d ? i += 1 : i -= 1), __b++) {
      results[i] = _.pluck(arguments, String(i));
    }
    return results;
  };
  // If the browser doesn't supply us with indexOf (I'm looking at you, MSIE),
  // we need this function. Return the position of the first occurence of an
  // item in an array, or -1 if the item is not included in the array.
  _.indexOf = function indexOf(array, item) {
    var i, l;
    if (array.indexOf) {
      return array.indexOf(item);
    }
    i = 0;
    l = array.length;
    while (l - i) {
      if (array[i] === item) {
        return i;
      } else {
        i++;
      }
    }
    return -1;
  };
  // Provide JavaScript 1.6's lastIndexOf, delegating to the native function,
  // if possible.
  _.lastIndexOf = function lastIndexOf(array, item) {
    var i;
    if (array.lastIndexOf) {
      return array.lastIndexOf(item);
    }
    i = array.length;
    while (i) {
      if (array[i] === item) {
        return i;
      } else {
        i--;
      }
    }
    return -1;
  };
  // Generate an integer Array containing an arithmetic progression. A port of
  // the native Python range() function. See:
  // http://docs.python.org/library/functions.html#range
  _.range = function range(start, stop, step) {
    var __a, a, i, idx, len, range, solo;
    var arguments = Array.prototype.slice.call(arguments, 0);
    a = arguments;
    solo = a.length <= 1;
    i = (start = solo ? 0 : a[0]);
    stop = solo ? a[0] : a[1];
    step = a[2] || 1;
    len = Math.ceil((stop - start) / step);
    if (len <= 0) {
      return [];
    }
    range = new Array(len);
    idx = 0;
    __a = [];
    while (true) {
      if ((step > 0 ? i - stop : stop - i) >= 0) {
        return range;
      }
      range[idx] = i;
      idx++;
      i += step;
    }
    return __a;
  };
  // ----------------------- Function Functions: -----------------------------
  // Create a function bound to a given object (assigning 'this', and arguments,
  // optionally). Binding with arguments is also known as 'curry'.
  _.bind = function bind(func, obj) {
    var args;
    var arguments = Array.prototype.slice.call(arguments, 0);
    args = _.rest(arguments, 2);
    return (function() {
      var arguments = Array.prototype.slice.call(arguments, 0);
      return func.apply(obj || root, args.concat(arguments));
    });
  };
  // Bind all of an object's methods to that object. Useful for ensuring that
  // all callbacks defined on an object belong to it.
  _.bindAll = function bindAll(obj) {
    var funcs;
    var arguments = Array.prototype.slice.call(arguments, 0);
    funcs = arguments.length > 1 ? _.rest(arguments) : _.functions(obj);
    _.each(funcs, function(f) {
      return obj[f] = _.bind(obj[f], obj);
    });
    return obj;
  };
  // Delays a function for the given number of milliseconds, and then calls
  // it with the arguments supplied.
  _.delay = function delay(func, wait) {
    var args;
    var arguments = Array.prototype.slice.call(arguments, 0);
    args = _.rest(arguments, 2);
    return setTimeout((function() {
      return func.apply(func, args);
    }), wait);
  };
  // Defers a function, scheduling it to run after the current call stack has
  // cleared.
  _.defer = function defer(func) {
    var arguments = Array.prototype.slice.call(arguments, 0);
    return _.delay.apply(_, [func, 1].concat(_.rest(arguments)));
  };
  // Returns the first function passed as an argument to the second,
  // allowing you to adjust arguments, run code before and after, and
  // conditionally execute the original function.
  _.wrap = function wrap(func, wrapper) {
    return (function() {
      var arguments = Array.prototype.slice.call(arguments, 0);
      return wrapper.apply(wrapper, [func].concat(arguments));
    });
  };
  // Returns a function that is the composition of a list of functions, each
  // consuming the return value of the function that follows.
  _.compose = function compose() {
    var funcs;
    var arguments = Array.prototype.slice.call(arguments, 0);
    funcs = arguments;
    return (function() {
      var __a, __b, __c, __d, args, i;
      var arguments = Array.prototype.slice.call(arguments, 0);
      args = arguments;
      __c = (funcs.length - 1); __d = 0;
      for (__b=0, i=__c; (__c <= __d ? i <= __d : i >= __d); (__c <= __d ? i += 1 : i -= 1), __b++) {
        args = [funcs[i].apply(this, args)];
      }
      return args[0];
    });
  };
  // ------------------------- Object Functions: ----------------------------
  // Retrieve the names of an object's properties.
  _.keys = function keys(obj) {
    var __a, __b, key, val;
    if (_.isArray(obj)) {
      return _.range(0, obj.length);
    }
    __a = []; __b = obj;
    for (key in __b) {
      val = __b[key];
      if (__hasProp.call(__b, key)) {
        __a.push(key);
      }
    }
    return __a;
  };
  // Retrieve the values of an object's properties.
  _.values = function values(obj) {
    return _.map(obj, _.identity);
  };
  // Return a sorted list of the function names available in Underscore.
  _.functions = function functions(obj) {
    return _.select(_.keys(obj), function(key) {
      return _.isFunction(obj[key]);
    }).sort();
  };
  // Extend a given object with all of the properties in a source object.
  _.extend = function extend(destination, source) {
    var __a, key, val;
    __a = source;
    for (key in __a) {
      val = __a[key];
      if (__hasProp.call(__a, key)) {
        destination[key] = val;
      }
    }
    return destination;
  };
  // Create a (shallow-cloned) duplicate of an object.
  _.clone = function clone(obj) {
    if (_.isArray(obj)) {
      return obj.slice(0);
    }
    return _.extend({}, obj);
  };
  // Invokes interceptor with the obj, and then returns obj.
  // The primary purpose of this method is to "tap into" a method chain, in order to perform operations on intermediate results within the chain.
  _.tap = function tap(obj, interceptor) {
    interceptor(obj);
    return obj;
  };
  // Perform a deep comparison to check if two objects are equal.
  _.isEqual = function isEqual(a, b) {
    var aKeys, atype, bKeys, btype;
    // Check object identity.
    if (a === b) {
      return true;
    }
    // Different types?
    atype = typeof (a);
    btype = typeof (b);
    if (atype !== btype) {
      return false;
    }
    // Basic equality test (watch out for coercions).
    if (a == b) {
      return true;
    }
    // One is falsy and the other truthy.
    if ((!a && b) || (a && !b)) {
      return false;
    }
    // One of them implements an isEqual()?
    if (a.isEqual) {
      return a.isEqual(b);
    }
    // Check dates' integer values.
    if (_.isDate(a) && _.isDate(b)) {
      return a.getTime() === b.getTime();
    }
    // Both are NaN?
    if (_.isNaN(a) && _.isNaN(b)) {
      return true;
    }
    // Compare regular expressions.
    if (_.isRegExp(a) && _.isRegExp(b)) {
      return a.source === b.source && a.global === b.global && a.ignoreCase === b.ignoreCase && a.multiline === b.multiline;
    }
    // If a is not an object by this point, we can't handle it.
    if (atype !== 'object') {
      return false;
    }
    // Check for different array lengths before comparing contents.
    if (a.length && (a.length !== b.length)) {
      return false;
    }
    // Nothing else worked, deep compare the contents.
    aKeys = _.keys(a);
    bKeys = _.keys(b);
    // Different object sizes?
    if (aKeys.length !== bKeys.length) {
      return false;
    }
    // Recursive comparison of contents.
    // for (var key in a) if (!_.isEqual(a[key], b[key])) return false;
    return true;
  };
  // Is a given array or object empty?
  _.isEmpty = function isEmpty(obj) {
    return _.keys(obj).length === 0;
  };
  // Is a given value a DOM element?
  _.isElement = function isElement(obj) {
    return obj && obj.nodeType === 1;
  };
  // Is a given value an array?
  _.isArray = function isArray(obj) {
    return !!(obj && obj.concat && obj.unshift);
  };
  // Is a given variable an arguments object?
  _.isArguments = function isArguments(obj) {
    return obj && _.isNumber(obj.length) && !obj.concat && !obj.substr && !obj.apply && !propertyIsEnumerable.call(obj, 'length');
  };
  // Is the given value a function?
  _.isFunction = function isFunction(obj) {
    return !!(obj && obj.constructor && obj.call && obj.apply);
  };
  // Is the given value a string?
  _.isString = function isString(obj) {
    return !!(obj === '' || (obj && obj.charCodeAt && obj.substr));
  };
  // Is a given value a number?
  _.isNumber = function isNumber(obj) {
    return (obj === +obj) || toString.call(obj) === '[object Number]';
  };
  // Is a given value a Date?
  _.isDate = function isDate(obj) {
    return !!(obj && obj.getTimezoneOffset && obj.setUTCFullYear);
  };
  // Is the given value a regular expression?
  _.isRegExp = function isRegExp(obj) {
    return !!(obj && obj.exec && (obj.ignoreCase || obj.ignoreCase === false));
  };
  // Is the given value NaN -- this one is interesting. NaN != NaN, and
  // isNaN(undefined) == true, so we make sure it's a number first.
  _.isNaN = function isNaN(obj) {
    return _.isNumber(obj) && window.isNaN(obj);
  };
  // Is a given value equal to null?
  _.isNull = function isNull(obj) {
    return obj === null;
  };
  // Is a given variable undefined?
  _.isUndefined = function isUndefined(obj) {
    return typeof obj === 'undefined';
  };
  // -------------------------- Utility Functions: --------------------------
  // Run Underscore.js in noConflict mode, returning the '_' variable to its
  // previous owner. Returns a reference to the Underscore object.
  _.noConflict = function noConflict() {
    root._ = previousUnderscore;
    return this;
  };
  // Keep the identity function around for default iterators.
  _.identity = function identity(value) {
    return value;
  };
  // Break out of the middle of an iteration.
  _.breakLoop = function breakLoop() {
    throw breaker;
  };
  // Generate a unique integer id (unique within the entire client session).
  // Useful for temporary DOM ids.
  idCounter = 0;
  _.uniqueId = function uniqueId(prefix) {
    return (prefix || '') + idCounter++;
  };
  // By default, Underscore uses ERB-style template delimiters, change the
  // following template settings to use alternative delimiters.
  _.templateSettings = {
    start: '<%',
    end: '%>',
    interpolate: /<%=(.+?)%>/g
  };
  // JavaScript templating a-la ERB, pilfered from John Resig's
  // "Secrets of the JavaScript Ninja", page 83.
  // Single-quotea fix from Rick Strahl's version.
  _.template = function template(str, data) {
    var c, fn;
    c = _.templateSettings;
    fn = new Function('obj', 'var p=[],print=function(){p.push.apply(p,arguments);};' + 'with(obj){p.push(\'' + str.replace(/[\r\t\n]/g, " ").replace(new RegExp("'(?=[^" + c.end[0] + "]*" + c.end + ")", "g"), "\t").split("'").join("\\'").split("\t").join("'").replace(c.interpolate, "',$1,'").split(c.start).join("');").split(c.end).join("p.push('") + "');}return p.join('');");
    return data ? fn(data) : fn;
  };
  // ------------------------------- Aliases ----------------------------------
  _.forEach = _.each;
  _.foldl = (_.inject = _.reduce);
  _.foldr = _.reduceRight;
  _.filter = _.select;
  _.every = _.all;
  _.some = _.any;
  _.head = _.first;
  _.tail = _.rest;
  _.methods = _.functions;
  // ------------------------ Setup the OOP Wrapper: --------------------------
  // Helper function to continue chaining intermediate results.
  result = function result(obj, chain) {
    return chain ? _(obj).chain() : obj;
  };
  // Add all of the Underscore functions to the wrapper object.
  _.each(_.functions(_), function(name) {
    var method;
    method = _[name];
    return wrapper.prototype[name] = function() {
      var arguments = Array.prototype.slice.call(arguments, 0);
      unshift.call(arguments, this._wrapped);
      return result(method.apply(_, arguments), this._chain);
    };
  });
  // Add all mutator Array functions to the wrapper.
  _.each(['pop', 'push', 'reverse', 'shift', 'sort', 'splice', 'unshift'], function(name) {
    var method;
    method = Array.prototype[name];
    return wrapper.prototype[name] = function() {
      var arguments = Array.prototype.slice.call(arguments, 0);
      method.apply(this._wrapped, arguments);
      return result(this._wrapped, this._chain);
    };
  });
  // Add all accessor Array functions to the wrapper.
  _.each(['concat', 'join', 'slice'], function(name) {
    var method;
    method = Array.prototype[name];
    return wrapper.prototype[name] = function() {
      var arguments = Array.prototype.slice.call(arguments, 0);
      return result(method.apply(this._wrapped, arguments), this._chain);
    };
  });
  // Start chaining a wrapped Underscore object.
  wrapper.prototype.chain = function chain() {
    this._chain = true;
    return this;
  };
  // Extracts the result from a wrapped and chained object.
  wrapper.prototype.value = function value() {
    return this._wrapped;
  };
})();