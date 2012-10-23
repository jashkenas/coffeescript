# Strict Early Errors
# -------------------

# The following are prohibited under ES5's `strict` mode
# * `Octal Integer Literals`
# * `Octal Escape Sequences`
# * duplicate property definitions in `Object Literal`s
# * duplicate formal parameter
# * `delete` operand is a variable
# * `delete` operand is a parameter
# * `delete` operand is `undefined`
# * `Future Reserved Word`s as identifiers: implements, interface, let, package, private, protected, public, static, yield
# * `eval` or `arguments` as `catch` identifier
# * `eval` or `arguments` as formal parameter
# * `eval` or `arguments` as function declaration identifier
# * `eval` or `arguments` as LHS of assignment
# * `eval` or `arguments` as the operand of a post/pre-fix inc/dec-rement expression

# helper to assert that code complies with strict prohibitions
strict = (code, msg) ->
  throws (-> CoffeeScript.compile code), null, msg ? code
strictOk = (code, msg) ->
  doesNotThrow (-> CoffeeScript.compile code), msg ? code


test "octal integer literals prohibited", ->
  strict    '01'
  strict    '07777'
  # decimals with a leading '0' are also prohibited
  strict    '09'
  strict    '079'
  strictOk  '`01`'

test "octal escape sequences prohibited", ->
  strict    '"\\1"'
  strict    '"\\7"'
  strict    '"\\001"'
  strict    '"\\777"'
  strict    '"_\\1"'
  strict    '"\\1_"'
  strict    '"_\\1_"'
  strict    '"\\\\\\1"'
  strictOk  '"\\0"'
  eq "\x00", "\0"
  strictOk  '"\\08"'
  eq "\x008", "\08"
  strictOk  '"\\0\\8"'
  eq "\x008", "\0\8"
  strictOk  '"\\8"'
  eq "8", "\8"
  strictOk  '"\\\\1"'
  eq "\\" + "1", "\\1"
  strictOk  '"\\\\\\\\1"'
  eq "\\\\" + "1", "\\\\1"
  strictOk  "`'\\1'`"
  eq "\\" + "1", `"\\1"`

test "duplicate formal parameters are prohibited", ->
  nonce = {}
  # a Param can be an Identifier, ThisProperty( @-param ), Array, or Object
  # a Param can also be a splat (...) or an assignment (param=value)
  # the following function expressions should throw errors
  strict '(_,_)->',          'param, param'
  strict '(_,@_)->',         'param, @param'
  strict '(_,_...)->',       'param, param...'
  strict '(@_,_...)->',      '@param, param...'
  strict '(_,_ = true)->',   'param, param='
  strict '(@_,@_)->',        'two @params'
  strict '(_,@_ = true)->',  'param, @param='
  strict '(_,{_})->',        'param, {param}'
  strict '(@_,{_})->',       '@param, {param}'
  strict '({_,_})->',        '{param, param}'
  strict '({_,@_})->',       '{param, @param}'
  strict '(_,[_])->',        'param, [param]'
  strict '([_,_])->',        '[param, param]'
  strict '([_,@_])->',       '[param, @param]'
  strict '(_,[_]=true)->',   'param, [param]='
  strict '(_,[@_,{_}])->',   'param, [@param, {param}]'
  strict '(_,[_,{@_}])->',   'param, [param, {@param}]'
  strict '(_,[_,{_}])->',    'param, [param, {param}]'
  strict '(_,[_,{__}])->',   'param, [param, {param2}]'
  strict '(_,[__,{_}])->',   'param, [param2, {param}]'
  strict '(__,[_,{_}])->',   'param, [param2, {param2}]'
  strict '(0:a,1:a)->',      '0:param,1:param'
  strict '({0:a,1:a})->',    '{0:param,1:param}'
  # the following function expressions should **not** throw errors
  strictOk '({},_arg)->'
  strictOk '({},{})->'
  strictOk '([]...,_arg)->'
  strictOk '({}...,_arg)->'
  strictOk '({}...,[],_arg)->'
  strictOk '([]...,{},_arg)->'
  strictOk '(@case,_case)->'
  strictOk '(@case,_case...)->'
  strictOk '(@case...,_case)->'
  strictOk '(_case,@case)->'
  strictOk '(_case,@case...)->'
  strictOk '(a:a)->'
  strictOk '(a:a,a:b)->'

test "`delete` operand restrictions", ->
  strict 'a = 1; delete a'
  strictOk 'delete a' #noop
  strict '(a) -> delete a'
  strict '(@a) -> delete a'
  strict '(a...) -> delete a'
  strict '(a = 1) -> delete a'
  strict '([a]) -> delete a'
  strict '({a}) -> delete a'

test "`Future Reserved Word`s, `eval` and `arguments` restrictions", ->

  access = (keyword, check = strict) ->
    check "#{keyword}.a = 1"
    check "#{keyword}[0] = 1"
  assign = (keyword, check = strict) ->
    check "#{keyword} = 1"
    check "#{keyword} += 1"
    check "#{keyword} -= 1"
    check "#{keyword} *= 1"
    check "#{keyword} /= 1"
    check "#{keyword} ?= 1"
    check "{keyword}++"
    check "++{keyword}"
    check "{keyword}--"
    check "--{keyword}"
  destruct = (keyword, check = strict) ->
    check "{#{keyword}}"
    check "o = {#{keyword}}"
  invoke = (keyword, check = strict) ->
    check "#{keyword} yes"
    check "do #{keyword}"
  fnDecl = (keyword, check = strict) ->
    check "class #{keyword}"
  param = (keyword, check = strict) ->
    check "(#{keyword}) ->"
    check "({#{keyword}}) ->"
  prop = (keyword, check = strict) ->
    check "a.#{keyword} = 1"
  tryCatch = (keyword, check = strict) ->
    check "try new Error catch #{keyword}"

  future = 'implements interface let package private protected public static yield'.split ' '
  for keyword in future
    access   keyword
    assign   keyword
    destruct keyword
    invoke   keyword
    fnDecl   keyword
    param    keyword
    prop     keyword, strictOk
    tryCatch keyword

  for keyword in ['eval', 'arguments']
    access   keyword, strictOk
    assign   keyword
    destruct keyword, strictOk
    invoke   keyword, strictOk
    fnDecl   keyword
    param    keyword
    prop     keyword, strictOk
    tryCatch keyword
