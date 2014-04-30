exports.OTest = class OTest

    # Jison DSL
    # ---------

    # Since we're going to be wrapped in a function by Jison in any case, if our
    # action immediately returns a value, we can optimize by removing the function
    # wrapper and just returning the value directly.
    unwrap = /^function\s*\(\)\s*\{\s*return\s*([\s\S]*);\s*\}/

    # Our handy DSL for Jison grammar generation, thanks to
    # [Tim Caswell](http://github.com/creationix). For every rule in the grammar,
    # we pass the pattern-defining string, the action to run, and extra options,
    # optionally. If no action is specified, we simply pass the value of the
    # previous nonterminal.
    o: (patternString, action, options) ->
      patternString = patternString.replace /\s{2,}/g, ' '
      patternCount = patternString.split(' ').length
      return [patternString, '$$ = $1;', options] unless action
      action = if match = unwrap.exec action then match[1] else "(#{action}())"

      # All runtime functions we need are defined on "yy"
      action = action.replace /\bnew /g, '$&yy.'
      action = action.replace /\b(?:Block\.wrap|extend)\b/g, 'yy.$&'

      # Returns a function which adds location data to the first parameter passed
      # in, and returns the parameter.  If the parameter is not a node, it will
      # just be passed through unaffected.
      addLocationDataFn = (first, last) ->
        if not last
          "yy.addLocationDataFn(@#{first})"
        else
          "yy.addLocationDataFn(@#{first}, @#{last})"

      action = action.replace /LOC\(([0-9]*)\)/g, addLocationDataFn('$1')
      action = action.replace /LOC\(([0-9]*),\s*([0-9]*)\)/g, addLocationDataFn('$1', '$2')

      [patternString, "$$ = #{addLocationDataFn(1, patternCount)}(#{action});", options]