
  # Underscore.coffee
  # (c) 2010 Jeremy Ashkenas, DocumentCloud Inc.
  # Underscore is freely distributable under the terms of the MIT license.
  # Portions of Underscore are inspired by or borrowed from Prototype.js,
  # Oliver Steele's Functional, and John Resig's Micro-Templating.
  # For all details and documentation:
  # http://documentcloud.github.com/underscore/


  # ------------------------- Baseline setup ---------------------------------

  # Establish the root object, "window" in the browser, or "global" on the server.
  root: this


  # Save the previous value of the "_" variable.
  previousUnderscore: root._


  # If Underscore is called as a function, it returns a wrapped object that
  # can be used OO-style. This wrapper holds altered versions of all the
  # underscore functions. Wrapped objects may be chained.
  wrapper: (obj) ->
    this._wrapped: obj
    this


  # Establish the object that gets thrown to break out of a loop iteration.
  breaker: if typeof(StopIteration) is 'undefined' then '__break__' else StopIteration


  # Create a safe reference to the Underscore object forreference below.
  _: root._: (obj) -> new wrapper(obj)


  # Export the Underscore object for CommonJS.
  if typeof(exports) != 'undefined' then exports._: _


  # Create quick reference variables for speed access to core prototypes.
  slice:                Array::slice
  unshift:              Array::unshift
  toString:             Object::toString
  hasOwnProperty:       Object::hasOwnProperty
  propertyIsEnumerable: Object::propertyIsEnumerable


  # Current version.
  _.VERSION: '0.5.7'


  # ------------------------ Collection Functions: ---------------------------

  # The cornerstone, an each implementation.
  # Handles objects implementing forEach, arrays, and raw objects.
  _.each: (obj, iterator, context) ->
    index: 0
    try
      return obj.forEach(iterator, context) if obj.forEach
      if _.isArray(obj) or _.isArguments(obj)
        return iterator.call(context, obj[i], i, obj) for i in [0...obj.length]
      iterator.call(context, val, key, obj) for key, val of obj
    catch e
      throw e if e isnt breaker
    obj


  # Return the results of applying the iterator to each element. Use JavaScript
  # 1.6's version of map, if possible.
  _.map: (obj, iterator, context) ->
    return obj.map(iterator, context) if (obj and _.isFunction(obj.map))
    results: []
    _.each obj, (value, index, list) ->
      results.push(iterator.call(context, value, index, list))
    results


  # Reduce builds up a single result from a list of values. Also known as
  # inject, or foldl. Uses JavaScript 1.8's version of reduce, if possible.
  _.reduce: (obj, memo, iterator, context) ->
    return obj.reduce(_.bind(iterator, context), memo) if (obj and _.isFunction(obj.reduce))
    _.each obj, (value, index, list) ->
      memo: iterator.call(context, memo, value, index, list)
    memo


  # The right-associative version of reduce, also known as foldr. Uses
  # JavaScript 1.8's version of reduceRight, if available.
  _.reduceRight: (obj, memo, iterator, context) ->
    return obj.reduceRight(_.bind(iterator, context), memo) if (obj and _.isFunction(obj.reduceRight))
    _.each _.clone(_.toArray(obj)).reverse(), (value, index) ->
      memo: iterator.call(context, memo, value, index, obj)
    memo


  # Return the first value which passes a truth test.
  _.detect: (obj, iterator, context) ->
    result: null
    _.each obj, (value, index, list) ->
      if iterator.call(context, value, index, list)
        result: value
        _.breakLoop()
    result


  # Return all the elements that pass a truth test. Use JavaScript 1.6's
  # filter(), if it exists.
  _.select: (obj, iterator, context) ->
    if obj and _.isFunction(obj.filter) then return obj.filter(iterator, context)
    results: []
    _.each obj, (value, index, list) ->
      results.push(value) if iterator.call(context, value, index, list)
    results


  # Return all the elements for which a truth test fails.
  _.reject: (obj, iterator, context) ->
    results: []
    _.each obj, (value, index, list) ->
      results.push(value) if not iterator.call(context, value, index, list)
    results


  # Determine whether all of the elements match a truth test. Delegate to
  # JavaScript 1.6's every(), if it is present.
  _.all: (obj, iterator, context) ->
    iterator ||= _.identity
    return obj.every(iterator, context) if obj and _.isFunction(obj.every)
    result: true
    _.each obj, (value, index, list) ->
      _.breakLoop() unless (result: result and iterator.call(context, value, index, list))
    result


  # Determine if at least one element in the object matches a truth test. Use
  # JavaScript 1.6's some(), if it exists.
  _.any: (obj, iterator, context) ->
    iterator ||= _.identity
    return obj.some(iterator, context) if obj and _.isFunction(obj.some)
    result: false
    _.each obj, (value, index, list) ->
      _.breakLoop() if (result: iterator.call(context, value, index, list))
    result


  # Determine if a given value is included in the array or object,
  # based on '==='.
  _.include: (obj, target) ->
    return _.indexOf(obj, target) isnt -1 if _.isArray(obj)
    for key, val of obj
      return true if val is target
    false


  # Invoke a method with arguments on every item in a collection.
  _.invoke: (obj, method) ->
    args: _.rest(arguments, 2)
    (if method then val[method] else val).apply(val, args) for val in obj


  # Convenience version of a common use case of map: fetching a property.
  _.pluck: (obj, key) ->
    _.map(obj, ((val) -> val[key]))


  # Return the maximum item or (item-based computation).
  _.max: (obj, iterator, context) ->
    return Math.max.apply(Math, obj) if not iterator and _.isArray(obj)
    result: {computed: -Infinity}
    _.each obj, (value, index, list) ->
      computed: if iterator then iterator.call(context, value, index, list) else value
      computed >= result.computed and (result: {value: value, computed: computed})
    result.value


  # Return the minimum element (or element-based computation).
  _.min: (obj, iterator, context) ->
    return Math.min.apply(Math, obj) if not iterator and _.isArray(obj)
    result: {computed: Infinity}
    _.each obj, (value, index, list) ->
      computed: if iterator then iterator.call(context, value, index, list) else value
      computed < result.computed and (result: {value: value, computed: computed})
    result.value


  # Sort the object's values by a criteria produced by an iterator.
  _.sortBy: (obj, iterator, context) ->
    _.pluck(((_.map obj, (value, index, list) ->
      {value: value, criteria: iterator.call(context, value, index, list)}
    ).sort((left, right) ->
      a: left.criteria; b: right.criteria
      if a < b then -1 else if a > b then 1 else 0
    )), 'value')


  # Use a comparator function to figure out at what index an object should
  # be inserted so as to maintain order. Uses binary search.
  _.sortedIndex: (array, obj, iterator) ->
    iterator ||= _.identity
    low: 0; high: array.length
    while low < high
      mid: (low + high) >> 1
      if iterator(array[mid]) < iterator(obj) then low: mid + 1 else high: mid
    low


  # Convert anything iterable into a real, live array.
  _.toArray: (iterable) ->
    return []                   if (!iterable)
    return iterable.toArray()   if (iterable.toArray)
    return iterable             if (_.isArray(iterable))
    return slice.call(iterable) if (_.isArguments(iterable))
    _.values(iterable)


  # Return the number of elements in an object.
  _.size: (obj) -> _.toArray(obj).length


  # -------------------------- Array Functions: ------------------------------

  # Get the first element of an array. Passing "n" will return the first N
  # values in the array. Aliased as "head". The "guard" check allows it to work
  # with _.map.
  _.first: (array, n, guard) ->
    if n and not guard then slice.call(array, 0, n) else array[0]


  # Returns everything but the first entry of the array. Aliased as "tail".
  # Especially useful on the arguments object. Passing an "index" will return
  # the rest of the values in the array from that index onward. The "guard"
  # check allows it to work with _.map.
  _.rest: (array, index, guard) ->
    slice.call(array, if _.isUndefined(index) or guard then 1 else index)


  # Get the last element of an array.
  _.last: (array) -> array[array.length - 1]


  # Trim out all falsy values from an array.
  _.compact: (array) -> array[i] for i in [0...array.length] when array[i]


  # Return a completely flattened version of an array.
  _.flatten: (array) ->
    _.reduce array, [], (memo, value) ->
      return memo.concat(_.flatten(value)) if _.isArray(value)
      memo.push(value)
      memo


  # Return a version of the array that does not contain the specified value(s).
  _.without: (array) ->
    values: _.rest(arguments)
    val for val in _.toArray(array) when not _.include(values, val)


  # Produce a duplicate-free version of the array. If the array has already
  # been sorted, you have the option of using a faster algorithm.
  _.uniq: (array, isSorted) ->
    memo: []
    for el, i in _.toArray(array)
      memo.push(el) if i is 0 || (if isSorted is true then _.last(memo) isnt el else not _.include(memo, el))
    memo


  # Produce an array that contains every item shared between all the
  # passed-in arrays.
  _.intersect: (array) ->
    rest: _.rest(arguments)
    _.select _.uniq(array), (item) ->
      _.all rest, (other) ->
        _.indexOf(other, item) >= 0


  # Zip together multiple lists into a single array -- elements that share
  # an index go together.
  _.zip: ->
    length:     _.max(_.pluck(arguments, 'length'))
    results:    new Array(length)
    for i in [0...length]
      results[i]: _.pluck(arguments, String(i))
    results


  # If the browser doesn't supply us with indexOf (I'm looking at you, MSIE),
  # we need this function. Return the position of the first occurence of an
  # item in an array, or -1 if the item is not included in the array.
  _.indexOf: (array, item) ->
    return array.indexOf(item) if array.indexOf
    i: 0; l: array.length
    while l - i
      if array[i] is item then return i else i++
    -1


  # Provide JavaScript 1.6's lastIndexOf, delegating to the native function,
  # if possible.
  _.lastIndexOf: (array, item) ->
    return array.lastIndexOf(item) if array.lastIndexOf
    i: array.length
    while i
      if array[i] is item then return i else i--
    -1


  # Generate an integer Array containing an arithmetic progression. A port of
  # the native Python range() function. See:
  # http://docs.python.org/library/functions.html#range
  _.range: (start, stop, step) ->
    a:        arguments
    solo:     a.length <= 1
    i: start: if solo then 0 else a[0];
    stop:     if solo then a[0] else a[1];
    step:     a[2] or 1
    len:      Math.ceil((stop - start) / step)
    return [] if len <= 0
    range:    new Array(len)
    idx:      0
    while true
      return range if (if step > 0 then i - stop else stop - i) >= 0
      range[idx]: i
      idx++
      i+= step


  # ----------------------- Function Functions: -----------------------------

  # Create a function bound to a given object (assigning 'this', and arguments,
  # optionally). Binding with arguments is also known as 'curry'.
  _.bind: (func, obj) ->
    args: _.rest(arguments, 2)
    -> func.apply(obj or root, args.concat(arguments))


  # Bind all of an object's methods to that object. Useful for ensuring that
  # all callbacks defined on an object belong to it.
  _.bindAll: (obj) ->
    funcs: if arguments.length > 1 then _.rest(arguments) else _.functions(obj)
    _.each(funcs, (f) -> obj[f]: _.bind(obj[f], obj))
    obj


  # Delays a function for the given number of milliseconds, and then calls
  # it with the arguments supplied.
  _.delay: (func, wait) ->
    args: _.rest(arguments, 2)
    setTimeout((-> func.apply(func, args)), wait)


  # Defers a function, scheduling it to run after the current call stack has
  # cleared.
  _.defer: (func) ->
    _.delay.apply(_, [func, 1].concat(_.rest(arguments)))


  # Returns the first function passed as an argument to the second,
  # allowing you to adjust arguments, run code before and after, and
  # conditionally execute the original function.
  _.wrap: (func, wrapper) ->
    -> wrapper.apply(wrapper, [func].concat(arguments))


  # Returns a function that is the composition of a list of functions, each
  # consuming the return value of the function that follows.
  _.compose: ->
    funcs: arguments
    ->
      args: arguments
      for i in [(funcs.length - 1)..0]
        args: [funcs[i].apply(this, args)]
      args[0]


  # ------------------------- Object Functions: ----------------------------

  # Retrieve the names of an object's properties.
  _.keys: (obj) ->
    return _.range(0, obj.length) if _.isArray(obj)
    key for key, val of obj


  # Retrieve the values of an object's properties.
  _.values: (obj) ->
    _.map(obj, _.identity)


  # Return a sorted list of the function names available in Underscore.
  _.functions: (obj) ->
    _.select(_.keys(obj), (key) -> _.isFunction(obj[key])).sort()


  # Extend a given object with all of the properties in a source object.
  _.extend: (destination, source) ->
    for key, val of source
      destination[key]: val
    destination


  # Create a (shallow-cloned) duplicate of an object.
  _.clone: (obj) ->
    return obj.slice(0) if _.isArray(obj)
    _.extend({}, obj)


  # Invokes interceptor with the obj, and then returns obj.
  # The primary purpose of this method is to "tap into" a method chain, in order to perform operations on intermediate results within the chain.
  _.tap: (obj, interceptor) ->
    interceptor(obj)
    obj


  # Perform a deep comparison to check if two objects are equal.
  _.isEqual: (a, b) ->
    # Check object identity.
    return true if a is b
    # Different types?
    atype: typeof(a); btype: typeof(b)
    return false if atype isnt btype
    # Basic equality test (watch out for coercions).
    return true if `a == b`
    # One is falsy and the other truthy.
    return false if (!a and b) or (a and !b)
    # One of them implements an isEqual()?
    return a.isEqual(b) if a.isEqual
    # Check dates' integer values.
    return a.getTime() is b.getTime() if _.isDate(a) and _.isDate(b)
    # Both are NaN?
    return true if _.isNaN(a) and _.isNaN(b)
    # Compare regular expressions.
    if _.isRegExp(a) and _.isRegExp(b)
      return a.source     is b.source and
             a.global     is b.global and
             a.ignoreCase is b.ignoreCase and
             a.multiline  is b.multiline
    # If a is not an object by this point, we can't handle it.
    return false if atype isnt 'object'
    # Check for different array lengths before comparing contents.
    return false if a.length and (a.length isnt b.length)
    # Nothing else worked, deep compare the contents.
    aKeys: _.keys(a); bKeys: _.keys(b)
    # Different object sizes?
    return false if aKeys.length isnt bKeys.length
    # Recursive comparison of contents.
    # for (var key in a) if (!_.isEqual(a[key], b[key])) return false;
    return true


  # Is a given array or object empty?
  _.isEmpty:      (obj) -> _.keys(obj).length is 0


  # Is a given value a DOM element?
  _.isElement:    (obj) -> obj and obj.nodeType is 1


  # Is a given value an array?
  _.isArray:      (obj) -> !!(obj and obj.concat and obj.unshift)


  # Is a given variable an arguments object?
  _.isArguments:  (obj) -> obj and _.isNumber(obj.length) and not obj.concat and
                           not obj.substr and not obj.apply and not propertyIsEnumerable.call(obj, 'length')


  # Is the given value a function?
  _.isFunction:   (obj) -> !!(obj and obj.constructor and obj.call and obj.apply)


  # Is the given value a string?
  _.isString:     (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))


  # Is a given value a number?
  _.isNumber:     (obj) -> (obj is +obj) or toString.call(obj) is '[object Number]'


  # Is a given value a Date?
  _.isDate:       (obj) -> !!(obj and obj.getTimezoneOffset and obj.setUTCFullYear)


  # Is the given value a regular expression?
  _.isRegExp:     (obj) -> !!(obj and obj.exec and (obj.ignoreCase or obj.ignoreCase is false))


  # Is the given value NaN -- this one is interesting. NaN != NaN, and
  # isNaN(undefined) == true, so we make sure it's a number first.
  _.isNaN:        (obj) -> _.isNumber(obj) and window.isNaN(obj)


  # Is a given value equal to null?
  _.isNull:       (obj) -> obj is null


  # Is a given variable undefined?
  _.isUndefined:  (obj) -> typeof obj is 'undefined'


  # -------------------------- Utility Functions: --------------------------

  # Run Underscore.js in noConflict mode, returning the '_' variable to its
  # previous owner. Returns a reference to the Underscore object.
  _.noConflict: ->
    root._: previousUnderscore
    this


  # Keep the identity function around for default iterators.
  _.identity: (value) -> value


  # Break out of the middle of an iteration.
  _.breakLoop: -> throw breaker


  # Generate a unique integer id (unique within the entire client session).
  # Useful for temporary DOM ids.
  idCounter: 0
  _.uniqueId: (prefix) ->
    (prefix or '') + idCounter++


  # By default, Underscore uses ERB-style template delimiters, change the
  # following template settings to use alternative delimiters.
  _.templateSettings: {
    start:        '<%'
    end:          '%>'
    interpolate:  /<%=(.+?)%>/g
  }


  # JavaScript templating a-la ERB, pilfered from John Resig's
  # "Secrets of the JavaScript Ninja", page 83.
  # Single-quotea fix from Rick Strahl's version.
  _.template: (str, data) ->
    c: _.templateSettings
    fn: new Function 'obj',
      'var p=[],print=function(){p.push.apply(p,arguments);};' +
      'with(obj){p.push(\'' +
      str.replace(/[\r\t\n]/g, " ")
         .replace(new RegExp("'(?=[^"+c.end[0]+"]*"+c.end+")","g"),"\t")
         .split("'").join("\\'")
         .split("\t").join("'")
         .replace(c.interpolate, "',$1,'")
         .split(c.start).join("');")
         .split(c.end).join("p.push('") +
         "');}return p.join('');"
    if data then fn(data) else fn


  # ------------------------------- Aliases ----------------------------------

  _.forEach: _.each
  _.foldl:   _.inject:      _.reduce
  _.foldr:   _.reduceRight
  _.filter:  _.select
  _.every:   _.all
  _.some:    _.any
  _.head:    _.first
  _.tail:    _.rest
  _.methods: _.functions


  #   /*------------------------ Setup the OOP Wrapper: --------------------------*/

  # Helper function to continue chaining intermediate results.
  result: (obj, chain) ->
    if chain then _(obj).chain() else obj


  # Add all of the Underscore functions to the wrapper object.
  _.each _.functions(_), (name) ->
    method: _[name]
    wrapper.prototype[name]: ->
      unshift.call(arguments, this._wrapped)
      result(method.apply(_, arguments), this._chain)


  # Add all mutator Array functions to the wrapper.
  _.each ['pop', 'push', 'reverse', 'shift', 'sort', 'splice', 'unshift'], (name) ->
    method: Array.prototype[name]
    wrapper.prototype[name]: ->
      method.apply(this._wrapped, arguments)
      result(this._wrapped, this._chain)


  # Add all accessor Array functions to the wrapper.
  _.each ['concat', 'join', 'slice'], (name) ->
    method: Array.prototype[name]
    wrapper.prototype[name]: ->
      result(method.apply(this._wrapped, arguments), this._chain)


  # Start chaining a wrapped Underscore object.
  wrapper::chain: ->
    this._chain: true
    this


  # Extracts the result from a wrapped and chained object.
  wrapper::value: -> this._wrapped
