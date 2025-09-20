# ==============================================================================
# CS3 Syntax - Data-Oriented Grammar for CoffeeScript 3
#
# Run `cake build:parser` to regenerate `lib/parser.js`
# ==============================================================================

o = (pattern, action, options) ->
  pattern = pattern.trim().replace /\s{2,}/g, ' '
  [pattern, action ? {$use: 1}, options]

grammar =
  Root: [
    o ''    , $ast: '@', body: []
    o 'Body', $ast: '@', body: 1
  ]

  Body: [
    o 'Line'                , $ary: [1]
    o 'Body TERMINATOR Line', $ops: 'array', append: [1, 3]
    o 'Body TERMINATOR'
  ]

  Line: [
    o 'Expression'
    o 'ExpressionLine'
    o 'Statement'
    o 'FuncDirective'
  ]

  FuncDirective: [
    o 'YieldReturn'
    o 'AwaitReturn'
  ]

  # Pure statements which cannot be expressions.
  Statement: [
    o 'Return'
    o 'STATEMENT', $ast: 'StatementLiteral', value: 1
    o 'Import'
    o 'Export'
  ]

  Expression: [
    o 'Value'
    o 'Code'
    o 'Operation'
    o 'Assign'
    o 'If'
    o 'Try'
    o 'While'
    o 'For'
    o 'Switch'
    o 'Class'
    o 'Throw'
    o 'Yield'
  ]

  # Expressions written on a single line and would otherwise need braces.
  ExpressionLine: [
    o 'CodeLine'
    o 'IfLine'
    o 'OperationLine'
  ]

  Yield: [
    o 'YIELD'                      , $ast: 'Op', args: [1, {$ast: 'Value'}]
    o 'YIELD Expression'           , $ast: 'Op', args: [1, 2]
    o 'YIELD INDENT Object OUTDENT', $ast: 'Op', args: [1, 3]
    o 'YIELD FROM Expression'      , $ast: 'Op', args: [{$use: 1, method: 'concat', args: [2]}, 3]
  ]

  # An indented block of expressions. Note that the [Rewriter](rewriter.html)
  # will convert some postfix forms into blocks for us, by adjusting the
  # token stream.
  Block: [
    o 'INDENT OUTDENT'     , $ast: '@'
    o 'INDENT Body OUTDENT', $use: 2
  ]

  Identifier: [
    o 'IDENTIFIER', $ast: 'IdentifierLiteral', value: 1
  ]

  Property: [
    o 'PROPERTY', $ast: 'PropertyName', value: {$use: 1, method: 'toString'}
  ]

  # Alphanumerics are separated from the other **Literal** matchers because
  # they can also serve as keys in object literals.
  AlphaNumeric: [
    o 'NUMBER', $ast: 'NumberLiteral', value: {$use: 1, method: 'toString'}, parsedValue: {$use: 1, prop: 'parsedValue'}
    o 'String'
  ]

  String: [
    o 'STRING'                                , $ast: 'StringLiteral', value: {$use: 1, method: 'slice', args: [1, -1]}, quote: {$use: 1, prop: 'quote'}, initialChunk: {$use: 1, prop: 'initialChunk'}, finalChunk: {$use: 1, prop: 'finalChunk'}, indent: {$use: 1, prop: 'indent'}, double: {$use: 1, prop: 'double'}, heregex: {$use: 1, prop: 'heregex'}
    o 'STRING_START Interpolations STRING_END', $ast: 'StringWithInterpolations', body: 2, quote: {$use: 1, prop: 'quote'}, startQuote: {$ast: 'Literal', value: {$use: 1, method: 'toString'}, $pos: 1}
  ]

  Interpolations: [
    o 'InterpolationChunk'               , $ary: [1]
    o 'Interpolations InterpolationChunk', $ops: 'array', append: [1, 2]
  ]

  InterpolationChunk: [
    o 'INTERPOLATION_START Body INTERPOLATION_END'               , $ast: 'Interpolation', expression: 2
    o 'INTERPOLATION_START INDENT Body OUTDENT INTERPOLATION_END', $ast: 'Interpolation', expression: 3
    o 'INTERPOLATION_START INTERPOLATION_END'                    , $ast: 'Interpolation'
    o 'String'                                                   , $use: 1
  ]

  # The .toString() calls here and elsewhere are to convert `String` objects
  # back to primitive strings now that we've retrieved stowaway extra properties
  Regex: [
    o 'REGEX'                           , $ast: 'RegexLiteral', value: {$use: 1, method: 'toString'}, delimiter: {$use: 1, prop: 'delimiter'}, heregexCommentTokens: {$use: 1, prop: 'heregexCommentTokens'}
    o 'REGEX_START Invocation REGEX_END', $ast: 'RegexWithInterpolations', invocation: 2, heregexCommentTokens: {$use: 3, prop: 'heregexCommentTokens'}
  ]

  # All of our immediate values. Generally these can be passed straight
  # through and printed to JavaScript.
  Literal: [
    o 'AlphaNumeric'
    o 'JS'          , $ast: 'PassthroughLiteral', value: {$use: 1, method: 'toString'}, here: {$use: 1, prop: 'here'}, generated: {$use: 1, prop: 'generated'}
    o 'Regex'
    o 'UNDEFINED'   , $ast: 'UndefinedLiteral', value: 1
    o 'NULL'        , $ast: 'NullLiteral', value: 1
    o 'BOOL'        , $ast: 'BooleanLiteral', value: {$use: 1, method: 'toString'}, originalValue: {$use: 1, prop: 'original'}
    o 'INFINITY'    , $ast: 'InfinityLiteral', value: {$use: 1, method: 'toString'}, originalValue: {$use: 1, prop: 'original'}
    o 'NAN'         , $ast: 'NaNLiteral', value: 1
  ]

  # Assignment of a variable, property, or index to a value.
  Assign: [
    o 'Assignable = Expression'               , $ast: '@', variable: 1, value: 3
    o 'Assignable = TERMINATOR Expression'    , $ast: '@', variable: 1, value: 4
    o 'Assignable = INDENT Expression OUTDENT', $ast: '@', variable: 1, value: 4
  ]

  # Assignment when it happens within an object literal. The difference from
  # the ordinary **Assign** is that these allow numbers and strings as keys.
  AssignObj: [
    o 'ObjAssignable'                                  , $ast: 'Value', val: 1
    o 'ObjRestValue'
    o 'ObjAssignable : Expression'                     , $ast: 'Assign', value: {$ast: 'Value', val: 1, $pos: 1}, expression: 3, context: 'object', operatorToken: {$ast: 'Literal', value: 2, $pos: 2}
    o 'ObjAssignable : INDENT Expression OUTDENT'      , $ast: 'Assign', value: {$ast: 'Value', val: 1, $pos: 1}, expression: 4, context: 'object', operatorToken: {$ast: 'Literal', value: 2, $pos: 2}
    o 'SimpleObjAssignable = Expression'               , $ast: 'Assign', value: {$ast: 'Value', val: 1, $pos: 1}, expression: 3, operatorToken: {$ast: 'Literal', value: 2, $pos: 2}
    o 'SimpleObjAssignable = INDENT Expression OUTDENT', $ast: 'Assign', value: {$ast: 'Value', val: 1, $pos: 1}, expression: 4, operatorToken: {$ast: 'Literal', value: 2, $pos: 2}
  ]

  SimpleObjAssignable: [
    o 'Identifier'
    o 'Property'
    o 'ThisProperty'
  ]

  ObjAssignable: [
    o 'SimpleObjAssignable'
    o '[ Expression ]'  , $ast: 'Value', value: {$ast: 'ComputedPropertyName', expression: 2}
    o '@ [ Expression ]', $ast: 'Value', val: {$ast: 'ThisLiteral', value: 1, $pos: 1}, properties: [{$ast: 'ComputedPropertyName', name: 3, $pos: 3}], context: 'this'
    o 'AlphaNumeric'
  ]

  # Object literal spread properties.
  ObjRestValue: [
    # Shorthand rest: `r...` — ensure identifier is captured
    o 'SimpleObjAssignable ...', $ast: 'Splat', name: {$ast: 'Value', val: 1}, postfix: false
    o '... SimpleObjAssignable', $ast: 'Splat', name: {$ast: 'Value', val: 2}, postfix: false
    o 'ObjSpreadExpr ...'      , $ast: 'Splat', name: 1
    o '... ObjSpreadExpr'      , $ast: 'Splat', name: 2, postfix: false
  ]

  ObjSpreadExpr: [
    o 'ObjSpreadIdentifier'
    o 'Object'
    o 'Parenthetical'
    o 'Super'
    o 'This'
    o 'SUPER OptFuncExist Arguments'              , $ast: 'SuperCall', variable: {$ast: 'Super'}, args: 3, soak: {$use: 2, prop: 'soak'}, token: 1
    o 'DYNAMIC_IMPORT Arguments'                  , $ast: 'DynamicImportCall', variable: {$ast: 'DynamicImport'}, args: 2
    o 'SimpleObjAssignable OptFuncExist Arguments', $ast: 'Call', variable: {$ast: 'Value', val: 1}, args: 3, soak: {$use: 2, prop: 'soak'}
    o 'ObjSpreadExpr OptFuncExist Arguments'      , $ast: 'Call', variable: 1, args: 3, soak: {$use: 2, prop: 'soak'}
  ]

  ObjSpreadIdentifier: [
    o 'SimpleObjAssignable Accessor', $ops: 'value', add: [1, 2]
    o 'ObjSpreadExpr Accessor'      , $ops: 'value', add: [1, 2]
  ]

  # A return statement from a function body.
  Return: [
    o 'RETURN Expression'           , $ast: '@', expression: 2
    o 'RETURN INDENT Object OUTDENT', $ast: '@', value: {$ast: 'Value'}
    o 'RETURN'                      , $ast: '@'
  ]

  YieldReturn: [
    o 'YIELD RETURN Expression', $ast: '@', expression: 3, returnKeyword: {$ast: 'Literal', value: 2, $pos: 2}
    o 'YIELD RETURN'           , $ast: '@', expression: null, returnKeyword: {$ast: 'Literal', value: 2, $pos: 2}
  ]

  AwaitReturn: [
    o 'AWAIT RETURN Expression', $ast: '@', expression: 3, returnKeyword: {$ast: 'Literal', value: 2, $pos: 2}
    o 'AWAIT RETURN'           , $ast: '@', expression: null, returnKeyword: {$ast: 'Literal', value: 2, $pos: 2}
  ]

  # The **Code** node is the function literal. It’s defined by an indented block
  # of **Block** preceded by a function arrow, with an optional parameter list.
  Code: [
    o 'PARAM_START ParamList PARAM_END FuncGlyph Block', $ast: '@', params: 2, body: 5, funcGlyph: 4, paramStart: {$ast: 'Literal', value: 1, $pos: 1}
    o 'FuncGlyph Block'                                , $ast: '@', params: [], body: 2, funcGlyph: 1
  ]

  # The Codeline is the **Code** node with **Line** instead of indented **Block**.
  CodeLine: [
    o 'PARAM_START ParamList PARAM_END FuncGlyph Line', $ast: 'Code', params: 2, body: [5], funcGlyph: 4, paramStart: {$ast: 'Literal', value: 1, $pos: 1}
    o 'FuncGlyph Line'                                , $ast: 'Code', params: [], body: [2], funcGlyph: 1
  ]

  # CoffeeScript has two different symbols for functions. `->` is for ordinary
  # functions, and `=>` is for functions bound to the current value of *this*.
  FuncGlyph: [
    o '->', $ast: '@', glyph: 1
    o '=>', $ast: '@', glyph: 1
  ]

  OptComma: [
    o ''
    o ','
  ]

  ParamList: [
    o ''                                                    , $ary: []
    o 'Param'                                               , $ary: [1]
    o 'ParamList , Param'                                   , $ops: 'array', append: [1, 3]
    o 'ParamList OptComma TERMINATOR Param'                 , $ops: 'array', append: [1, 4]
    o 'ParamList OptComma INDENT ParamList OptComma OUTDENT', $ops: 'array', append: [1, 4]
  ]

  Param: [
    o 'ParamVar'             , $ast: '@', name: 1
    o 'ParamVar ...'         , $ast: '@', name: 1, value: null, splat: true
    o '... ParamVar'         , $ast: '@', name: 2, value: null, splat: true, postfix: false
    o 'ParamVar = Expression', $ast: '@', name: 1, value: 3
    o '...'                  , $ast: 'Expansion'
  ]

  ParamVar: [
    o 'Identifier'
    # Treat @ inside destructuring params as a name to be lowered later,
    # not as assignment to `this` during parsing.
    o 'ThisProperty'
    o 'Array'
    o 'Object'
  ]

  Splat: [
    # Keep original behavior for general splats
    o 'Expression ...', $ast: '@', body: 1
    o '... Expression', $ast: '@', name: 2, postfix: false
  ]

  SimpleAssignable: [
    o 'Identifier'    , $ast: 'Value', val: 1
    o 'Value Accessor', $ops: 'value', add: [1, 2]
    o 'Code Accessor' , $ops: 'value', add: [1, 2]
    o 'ThisProperty'
  ]

  Assignable: [
    o 'SimpleAssignable'
    o 'Array'           , $ast: 'Value', val: 1
    o 'Object'          , $ast: 'Value', val: 1
  ]

  # The types of things that can be treated as values
  Value: [
    o 'Assignable'
    o 'Literal'      , $ast: '@', val: 1
    o 'Parenthetical', $ast: '@', val: 1
    o 'Range'        , $ast: '@', val: 1
    o 'Invocation'   , $ast: '@', val: 1
    o 'DoIife'       , $ast: '@', val: 1
    o 'This'
    o 'Super'        , $ast: '@', val: 1
    o 'MetaProperty' , $ast: '@', val: 1
  ]

  # A `super`-based expression that can be used as a value.
  Super: [
    o 'SUPER . Property'                                     , $ast: '@', accessor: {$ast: 'Access', name: 3, $pos: 3}, literal: {$ast: 'Literal', value: 1, $pos: 1}
    o 'SUPER INDEX_START Expression INDEX_END'               , $ast: '@', accessor: {$ast: 'Index', name: 3, $pos: 3}, literal: {$ast: 'Literal', value: 1, $pos: 1}
    o 'SUPER INDEX_START INDENT Expression OUTDENT INDEX_END', $ast: '@', accessor: {$ast: 'Index', name: 4, $pos: 4}, literal: {$ast: 'Literal', value: 1, $pos: 1}
  ]

  # A “meta-property” access e.g. `new.target` or `import.meta`, where
  # something that looks like a property is referenced on a keyword.
  MetaProperty: [
    o 'NEW_TARGET . Property' , $ast: '@', identifier: {$ast: 'IdentifierLiteral', value: 1, $pos: 1}, accessor: {$ast: 'Access', name: 3, $pos: 3}
    o 'IMPORT_META . Property', $ast: '@', identifier: {$ast: 'IdentifierLiteral', value: 1, $pos: 1}, accessor: {$ast: 'Access', name: 3, $pos: 3}
  ]

  Accessor: [
    o '.  Property' , $ast: 'Access', name: 2
    o '?. Property' , $ast: 'Access', name: 2, soak: true
    o ':: Property' , $ary: [{$ast: 'Access', name: {$ast: 'PropertyName', value: 'prototype'}, shorthand: true, $pos: 1}, {$ast: 'Access', name: 2, $pos: 2}]
    o '?:: Property', $ary: [{$ast: 'Access', name: {$ast: 'PropertyName', value: 'prototype'}, shorthand: true, soak: true, $pos: 1}, {$ast: 'Access', name: 2, $pos: 2}]
    o '::'          , $ast: 'Access', name: {$ast: 'PropertyName', value: 'prototype'}, shorthand: true
    o '?::'         , $ast: 'Access', name: {$ast: 'PropertyName', value: 'prototype'}, shorthand: true, soak: true
    o 'Index'
  ]

  Index: [
    o 'INDEX_START IndexValue INDEX_END'               , $use: 2
    o 'INDEX_START INDENT IndexValue OUTDENT INDEX_END', $use: 3
    o 'INDEX_SOAK  Index'                              , $ops: 'prop', set: {target: 2, property: 'soak', value: true}
  ]

  IndexValue: [
    o 'Expression', $ast: 'Index', object: 1
    o 'Slice'     , $ast: 'Slice', range: 1
  ]

  # Object literals are simply lists of assignments.
  Object: [
    o '{ AssignList OptComma }', $ast: 'Obj', properties: 2, generated: {$use: 1, prop: 'generated'}
  ]

  # Assignment of properties within an object literal can be separated by
  # comma, as in JavaScript, or simply by newline.
  AssignList: [
    o ''                                                      , $ary: []
    o 'AssignObj'                                             , $ary: [1]
    o 'AssignList , AssignObj'                                , $ops: 'array', append: [1, 3]
    o 'AssignList OptComma TERMINATOR AssignObj'              , $ops: 'array', append: [1, 4]
    o 'AssignList OptComma INDENT AssignList OptComma OUTDENT', $ops: 'array', append: [1, 4]
  ]

  # Class definitions have optional bodies of prototype property assignments,
  # and optional references to the superclass.
  Class: [
    o 'CLASS'                                          , $ast: '@'
    o 'CLASS Block'                                    , $ast: '@', variable: null, parent: null, body: 2
    o 'CLASS EXTENDS Expression'                       , $ast: '@', variable: null, parent: 3
    o 'CLASS EXTENDS Expression Block'                 , $ast: '@', variable: null, parent: 3, body: 4
    o 'CLASS SimpleAssignable'                         , $ast: '@', variable: 2
    o 'CLASS SimpleAssignable Block'                   , $ast: '@', variable: 2, parent: null, body: 3
    o 'CLASS SimpleAssignable EXTENDS Expression'      , $ast: '@', variable: 2, parent: 4
    o 'CLASS SimpleAssignable EXTENDS Expression Block', $ast: '@', variable: 2, parent: 4, body: 5
  ]

  Import: [
    o 'IMPORT String'                                                                             , $ast: 'ImportDeclaration', clause: null, source: 2
    o 'IMPORT String ASSERT Object'                                                               , $ast: 'ImportDeclaration', clause: null, source: 2, assertions: 4
    o 'IMPORT ImportDefaultSpecifier FROM String'                                                 , $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: 2, namedImports: null}, source: 4
    o 'IMPORT ImportDefaultSpecifier FROM String ASSERT Object'                                   , $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: 2, namedImports: null}, source: 4, assertions: 6
    o 'IMPORT ImportNamespaceSpecifier FROM String'                                               , $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: null, namedImports: 2}, source: 4
    o 'IMPORT ImportNamespaceSpecifier FROM String ASSERT Object'                                 , $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: null, namedImports: 2}, source: 4, assertions: 6
    o 'IMPORT { } FROM String'                                                                    , $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: null, namedImports: {$ast: 'ImportSpecifierList'}}, source: 5
    o 'IMPORT { } FROM String ASSERT Object'                                                      , $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: null, namedImports: {$ast: 'ImportSpecifierList'}}, source: 5, assertions: 7
    o 'IMPORT { ImportSpecifierList OptComma } FROM String'                                       , $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: null, namedImports: {$ast: 'ImportSpecifierList', specifiers: 3}}, source: 7
    o 'IMPORT { ImportSpecifierList OptComma } FROM String ASSERT Object'                         , $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: null, namedImports: {$ast: 'ImportSpecifierList', specifiers: 3}}, source: 7, assertions: 9
    o 'IMPORT ImportDefaultSpecifier , ImportNamespaceSpecifier FROM String'                      , $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: 2, namedImports: 4}, source: 6
    o 'IMPORT ImportDefaultSpecifier , ImportNamespaceSpecifier FROM String ASSERT Object'        , $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: 2, namedImports: 4}, source: 6, assertions: 8
    o 'IMPORT ImportDefaultSpecifier , { ImportSpecifierList OptComma } FROM String'              , $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: 2, namedImports: {$ast: 'ImportSpecifierList', specifiers: 5}}, source: 9
    o 'IMPORT ImportDefaultSpecifier , { ImportSpecifierList OptComma } FROM String ASSERT Object', $ast: 'ImportDeclaration', clause: {$ast: 'ImportClause', defaultBinding: 2, namedImports: {$ast: 'ImportSpecifierList', specifiers: 5}}, source: 9, assertions: 11
  ]

  ImportSpecifierList: [
    o 'ImportSpecifier'                                                         , $ary: [1]
    o 'ImportSpecifierList , ImportSpecifier'                                   , $ops: 'array', append: [1, 3]
    o 'ImportSpecifierList OptComma TERMINATOR ImportSpecifier'                 , $ops: 'array', append: [1, 4]
    o 'INDENT ImportSpecifierList OptComma OUTDENT'                             , $use: 2
    o 'ImportSpecifierList OptComma INDENT ImportSpecifierList OptComma OUTDENT', $ops: 'array', append: [1, 4]
  ]

  ImportSpecifier: [
    o 'Identifier'              , $ast: '@', imported: 1
    o 'Identifier AS Identifier', $ast: '@', imported: 1, local: 3
    o 'DEFAULT'                 , $ast: '@', value: {$ast: 'DefaultLiteral'}
    o 'DEFAULT AS Identifier'   , $ast: '@', imported: {$ast: 'DefaultLiteral'}, local: 3
  ]

  ImportDefaultSpecifier: [
    o 'Identifier', $ast: '@', value: 1
  ]

  ImportNamespaceSpecifier: [
    o 'IMPORT_ALL AS Identifier', $ast: '@', star: {$ast: 'Literal', value: 1}, local: 3
  ]

  Export: [
    o 'EXPORT { }'                                                       , $ast: 'ExportNamedDeclaration', clause: {$ast: 'ExportSpecifierList'}
    o 'EXPORT { ExportSpecifierList OptComma }'                          , $ast: 'ExportNamedDeclaration', clause: {$ast: 'ExportSpecifierList', specifiers: 3}
    o 'EXPORT Class'                                                     , $ast: 'ExportNamedDeclaration', clause: 2
    o 'EXPORT Identifier = Expression'                                   , $ast: 'ExportNamedDeclaration', clause: {$ast: 'Assign', variable: 2, value: 4, moduleDeclaration: 'export'}
    o 'EXPORT Identifier = TERMINATOR Expression'                        , $ast: 'ExportNamedDeclaration', clause: {$ast: 'Assign', variable: 2, value: 5, moduleDeclaration: 'export'}
    o 'EXPORT Identifier = INDENT Expression OUTDENT'                    , $ast: 'ExportNamedDeclaration', clause: {$ast: 'Assign', variable: 2, value: 5, moduleDeclaration: 'export'}
    o 'EXPORT DEFAULT Expression'                                        , $ast: 'ExportDefaultDeclaration', declaration: 3
    o 'EXPORT DEFAULT INDENT Object OUTDENT'                             , $ast: 'ExportDefaultDeclaration', value: {$ast: 'Value'}
    o 'EXPORT EXPORT_ALL FROM String'                                    , $ast: 'ExportAllDeclaration', exported: {$ast: 'Literal', value: 2}, source: 4
    o 'EXPORT EXPORT_ALL FROM String ASSERT Object'                      , $ast: 'ExportAllDeclaration', exported: {$ast: 'Literal', value: 2}, source: 4, assertions: 6
    o 'EXPORT { } FROM String'                                           , $ast: 'ExportNamedDeclaration', clause: {$ast: 'ExportSpecifierList'}, source: 5
    o 'EXPORT { } FROM String ASSERT Object'                             , $ast: 'ExportNamedDeclaration', clause: {$ast: 'ExportSpecifierList'}, source: 5, assertions: 7
    o 'EXPORT { ExportSpecifierList OptComma } FROM String'              , $ast: 'ExportNamedDeclaration', clause: {$ast: 'ExportSpecifierList', specifiers: 3}, source: 7
    o 'EXPORT { ExportSpecifierList OptComma } FROM String ASSERT Object', $ast: 'ExportNamedDeclaration', clause: {$ast: 'ExportSpecifierList', specifiers: 3}, source: 7, assertions: 9
  ]

  ExportSpecifierList: [
    o 'ExportSpecifier'                                                         , $ary: [1]
    o 'ExportSpecifierList , ExportSpecifier'                                   , $ops: 'array', append: [1, 3]
    o 'ExportSpecifierList OptComma TERMINATOR ExportSpecifier'                 , $ops: 'array', append: [1, 4]
    o 'INDENT ExportSpecifierList OptComma OUTDENT'                             , $use: 2
    o 'ExportSpecifierList OptComma INDENT ExportSpecifierList OptComma OUTDENT', $ops: 'array', append: [1, 4]
  ]

  ExportSpecifier: [
    o 'Identifier'              , $ast: '@', local: 1
    o 'Identifier AS Identifier', $ast: '@', local: 1, exported: 3
    o 'Identifier AS DEFAULT'   , $ast: '@', local: 1, exported: {$ast: 'DefaultLiteral', value: 3, $pos: 3}
    o 'DEFAULT'                 , $ast: '@', value: {$ast: 'DefaultLiteral'}
    o 'DEFAULT AS Identifier'   , $ast: '@', local: {$ast: 'DefaultLiteral'}, exported: 3
  ]

  # Ordinary function invocation, or a chained series of calls.
  Invocation: [
    o 'Value OptFuncExist String'   , $ast: 'TaggedTemplateCall', variable: 1, template: 3, soak: {$use: 2, prop: 'soak'}
    o 'Value OptFuncExist Arguments', $ast: 'Call', variable: 1, args: 3, soak: {$use: 2, prop: 'soak'}
    o 'SUPER OptFuncExist Arguments', $ast: 'SuperCall', variable: {$ast: 'Super'}, args: 3, soak: {$use: 2, prop: 'soak'}, token: 1
    o 'DYNAMIC_IMPORT Arguments'    , $ast: 'DynamicImportCall', variable: {$ast: 'DynamicImport'}, args: 2
  ]

  # An optional existence check on a function.
  OptFuncExist: [
    o ''          , soak: false
    o 'FUNC_EXIST', soak: true
  ]

  # The list of arguments to a function call.
  Arguments: [
    o 'CALL_START CALL_END'                 , $ary: [{}]
    o 'CALL_START ArgList OptComma CALL_END', $ary: 2, implicit: {$use: 1, prop: 'generated'}
  ]

  # A reference to the *this* current object.
  This: [
    o 'THIS', $ast: 'Value', value: {$ast: 'ThisLiteral'}
    o '@'   , $ast: 'Value', value: {$ast: 'ThisLiteral'}
  ]

  # A reference to a property on *this*.
  ThisProperty: [
    o '@ Property', $ast: 'Value', val: {$ast: 'ThisLiteral'}, properties: [{$ast: 'Access', name: 2}], bareLiteral: {$ast: 'ThisLiteral'}
  ]

  # The array literal.
  Array: [
    o '[ ]'                           , $ast: 'Arr', value: {$ary: [{}]}
    o '[ Elisions ]'                  , $ast: 'Arr', objects: 2
    o '[ ArgElisionList OptElisions ]', $ast: 'Arr', objects: {$ops: 'array', gather: [[], 2]}, elisions: 3
  ]

  # Inclusive and exclusive range dots.
  RangeDots: [
    o '..' , exclusive: false
    o '...', exclusive: true
  ]

  # The CoffeeScript range literal.
  Range: [
    o '[ Expression RangeDots Expression ]'    , $ast: '@', from: 2, to: 4, exclusive: {$use: 3, prop: 'exclusive'}
    o '[ ExpressionLine RangeDots Expression ]', $ast: '@', from: 2, to: 4, exclusive: {$use: 3, prop: 'exclusive'}
  ]

  # Array slice literals.
  Slice: [
    o 'Expression RangeDots Expression'    , $ast: 'Range', from: 1, to: 3, exclusive: {$use: 2, prop: 'exclusive'}
    o 'Expression RangeDots'               , $ast: 'Range', from: 1, to: null, exclusive: {$use: 2, prop: 'exclusive'}
    o 'ExpressionLine RangeDots Expression', $ast: 'Range', from: 1, to: 3, exclusive: {$use: 2, prop: 'exclusive'}
    o 'ExpressionLine RangeDots'           , $ast: 'Range', from: 1, to: null, exclusive: {$use: 2, prop: 'exclusive'}
    o 'RangeDots Expression'               , $ast: 'Range', from: null, to: 2, exclusive: {$use: 1, prop: 'exclusive'}
    o 'RangeDots'                          , $ast: 'Range', from: null, to: null, exclusive: {$use: 1, prop: 'exclusive'}
  ]

  # The **ArgList** is the list of objects passed into a function call
  # (i.e. comma-separated expressions). Newlines work as well.
  ArgList: [
    o 'Arg'                                             , $ary: [1]
    o 'ArgList , Arg'                                   , $ops: 'array', append: [1, 3]
    o 'ArgList OptComma TERMINATOR Arg'                 , $ops: 'array', append: [1, 4]
    o 'INDENT ArgList OptComma OUTDENT'                 , $use: 2
    o 'ArgList OptComma INDENT ArgList OptComma OUTDENT', $ops: 'array', append: [1, 4]
  ]

  # Valid arguments are Blocks or Splats.
  Arg: [
    o 'Expression'
    o 'ExpressionLine'
    o 'Splat'
    o '...', $ast: 'Expansion'
  ]

  # The **ArgElisionList** is the list of objects, contents of an array literal
  # (i.e. comma-separated expressions and elisions). Newlines work as well.
  ArgElisionList: [
    o 'ArgElision'
    o 'ArgElisionList , ArgElision'                                         , $ops: 'array', append: [1, 3]
    o 'ArgElisionList OptComma TERMINATOR ArgElision'                       , $ops: 'array', append: [1, 4]
    o 'INDENT ArgElisionList OptElisions OUTDENT'                           , $ops: 'array', append: [2, 3]
    o 'ArgElisionList OptElisions INDENT ArgElisionList OptElisions OUTDENT', $ops: 'array', gather: [1, 2, 4, 5]
  ]

  ArgElision: [
    o 'Arg'         , $ary: [1]
    o 'Elisions Arg', $ops: 'array', append: [1, 2]
  ]

  OptElisions: [
    o 'OptComma'  , $ary: [{}]
    o ', Elisions', $ops: 'array', gather: [[], 2]
  ]

  Elisions: [
    o 'Elision'         , $ary: [1]
    o 'Elisions Elision', $ops: 'array', append: [1, 2]
  ]

  Elision: [
    o ','                 , $ast: '@'
    o 'Elision TERMINATOR', $use: 1
  ]

  # Just simple, comma-separated, required arguments (no fancy syntax). We need
  # this to be separate from the **ArgList** for use in **Switch** blocks, where
  # having the newlines wouldn't make sense.
  SimpleArgs: [
    o 'Expression'
    o 'ExpressionLine'
    o 'SimpleArgs , Expression'    , $ops: 'array', gather: [1, 3]
    o 'SimpleArgs , ExpressionLine', $ops: 'array', gather: [1, 3]
  ]

  # The variants of *try/catch/finally* exception handling blocks.
  Try: [
    o 'TRY Block'                    , $ast: '@', attempt: 2
    o 'TRY Block Catch'              , $ast: '@', attempt: 2, catch: 3
    o 'TRY Block FINALLY Block'      , $ast: '@', attempt: 2, catch: null, ensure: 4, finallyTag: {$ast: 'Literal', value: 3}
    o 'TRY Block Catch FINALLY Block', $ast: '@', attempt: 2, catch: 3, ensure: 5, finallyTag: {$ast: 'Literal', value: 4}
  ]

  # A catch clause names its error and runs a block of code.
  Catch: [
    o 'CATCH Identifier Block', $ast: '@', recovery: 3, variable: 2
    o 'CATCH Object Block'    , $ast: '@', body: 3, errorVariable: {$ast: 'Value', val: 2}
    o 'CATCH Block'           , $ast: '@', recovery: 2
  ]

  # Throw an exception object.
  Throw: [
    o 'THROW Expression'           , $ast: '@', expression: 2
    o 'THROW INDENT Object OUTDENT', $ast: '@', value: {$ast: 'Value'}
  ]

  # Parenthetical expressions. Note that the **Parenthetical** is a **Value**,
  # not an **Expression**, so if you need to use an expression in a place
  # where only values are accepted, wrapping it in parentheses will always do
  # the trick.
  Parenthetical: [
    o '( Body )'               , $ast: 'Parens', body: 2
    o '( INDENT Body OUTDENT )', $ast: 'Parens', body: 3
  ]

  # The condition portion of a while loop.
  WhileLineSource: [
    o 'WHILE ExpressionLine'                    , $ast: 'While', condition: 2
    o 'WHILE ExpressionLine WHEN ExpressionLine', $ast: 'While', condition: 2, guard: 4
    o 'UNTIL ExpressionLine'                    , $ast: 'While', condition: 2, invert: true
    o 'UNTIL ExpressionLine WHEN ExpressionLine', $ast: 'While', condition: 2, invert: true, guard: 4
  ]

  WhileSource: [
    o 'WHILE Expression'                    , $ast: 'While', condition: 2
    o 'WHILE Expression WHEN Expression'    , $ast: 'While', condition: 2, guard: 4
    o 'WHILE ExpressionLine WHEN Expression', $ast: 'While', condition: 2, guard: 4
    o 'UNTIL Expression'                    , $ast: 'While', condition: 2, invert: true
    o 'UNTIL Expression WHEN Expression'    , $ast: 'While', condition: 2, invert: true, guard: 4
    o 'UNTIL ExpressionLine WHEN Expression', $ast: 'While', condition: 2, invert: true, guard: 4
  ]

  # The while loop can either be normal, with a block of expressions to execute,
  # or postfix, with a single expression. There is no do..while.
  While: [
    o 'WhileSource Block'     , $ops: 'loop', addBody: [1, 'Body $2']
    o 'WhileLineSource Block' , $ops: 'loop', addBody: [1, 'Body $2']
    o 'Statement  WhileSource', $ops: 'loop', addBody: [2, [1]], postfix: true
    o 'Expression WhileSource', $ops: 'loop', addBody: [2, [1]], postfix: true
    o 'Loop'                  , $use: 1
  ]

  Loop: [
    o 'LOOP Block'     , $ast: 'While', condition: {$ast: 'BooleanLiteral', value: 'true'}, isLoop: true, body: 2
    o 'LOOP Expression', $ast: 'While', condition: {$ast: 'BooleanLiteral', value: 'true'}, isLoop: true, body: [2]
  ]

  # Array, object, and range comprehensions, at the most generic level.
  # Comprehensions can either be normal, with a block of expressions to execute,
  # or postfix, with a single expression.
  For: [
    o 'Statement    ForBody', $ops: 'loop', addBody: [2, 1], postfix: true
    o 'Expression   ForBody', $ops: 'loop', addBody: [2, 1], postfix: true
    o 'ForBody      Block'  , $ops: 'loop', addBody: [1, 'Body $2']
    o 'ForLineBody  Block'  , $ops: 'loop', addBody: [1, 'Body $2']
  ]

  ForBody: [
    o 'FOR Range'              , $ast: 'For', body: {$ary: []}, source: {$ast: 'Value', val: 2, $pos: 2}
    o 'FOR Range BY Expression', $ast: 'For', body: {$ary: []}, source: {$ast: 'Value', val: 2, $pos: 2}, step: 4
    o 'ForStart ForSource'     , $ops: 'loop', addSource: [1, 2]
  ]

  ForLineBody: [
    o 'FOR Range BY ExpressionLine', $ast: 'For', body: {$ary: []}, source: {$ast: 'Value', val: 2, $pos: 2}, step: 4
    o 'ForStart ForLineSource'     , $ops: 'loop', addSource: [1, 2]
  ]

  ForStart: [
    o 'FOR ForVariables'      , $ast: 'For', body: {$ary: [{}]}, name: {$use: 2, index: 0}, index: {$use: 2, index: 1}
    o 'FOR AWAIT ForVariables', $ast: 'For', body: {$ary: []}, name: {$use: 3, index: 0}, index: {$use: 3, index: 1}, await: true, awaitTag: {$ast: 'Literal', value: 2, $pos: 2}
    o 'FOR OWN ForVariables'  , $ast: 'For', body: {$ary: []}, name: {$use: 3, index: 0}, index: {$use: 3, index: 1}, own: true, ownTag: {$ast: 'Literal', value: 2, $pos: 2}
  ]

  # An array of all accepted values for a variable inside the loop.
  # This enables support for pattern matching.
  ForValue: [
    o 'Identifier'
    o 'ThisProperty'
    o 'Array' , $ast: 'Value', val: 1
    o 'Object', $ast: 'Value', val: 1
  ]

  # An array or range comprehension has variables for the current element
  # and (optional) reference to the current index. Or, *key, value*, in the case
  # of object comprehensions.
  ForVariables: [
    o 'ForValue'           , $ary: [1]
    o 'ForValue , ForValue', $ary: [1, 3]
  ]

  # The source of a comprehension is an array or object with an optional guard
  # clause. If it’s an array comprehension, you can also choose to step through
  # in fixed-size increments.
  ForSource: [
    o 'FORIN Expression'                                      , source: 2
    o 'FOROF Expression'                                      , source: 2, object: true
    o 'FORIN Expression WHEN Expression'                      , source: 2, guard: 4
    o 'FORIN ExpressionLine WHEN Expression'                  , source: 2, guard: 4
    o 'FOROF Expression WHEN Expression'                      , source: 2, guard: 4, object: true
    o 'FOROF ExpressionLine WHEN Expression'                  , source: 2, guard: 4, object: true
    o 'FORIN Expression BY Expression'                        , source: 2, step: 4
    o 'FORIN ExpressionLine BY Expression'                    , source: 2, step: 4
    o 'FORIN Expression WHEN Expression BY Expression'        , source: 2, guard: 4, step: 6
    o 'FORIN ExpressionLine WHEN Expression BY Expression'    , source: 2, guard: 4, step: 6
    o 'FORIN Expression WHEN ExpressionLine BY Expression'    , source: 2, guard: 4, step: 6
    o 'FORIN ExpressionLine WHEN ExpressionLine BY Expression', source: 2, guard: 4, step: 6
    o 'FORIN Expression BY Expression WHEN Expression'        , source: 2, step: 4, guard: 6
    o 'FORIN ExpressionLine BY Expression WHEN Expression'    , source: 2, step: 4, guard: 6
    o 'FORIN Expression BY ExpressionLine WHEN Expression'    , source: 2, step: 4, guard: 6
    o 'FORIN ExpressionLine BY ExpressionLine WHEN Expression', source: 2, step: 4, guard: 6
    o 'FORFROM Expression'                                    , source: 2, from: true
    o 'FORFROM Expression WHEN Expression'                    , source: 2, guard: 4, from: true
    o 'FORFROM ExpressionLine WHEN Expression'                , source: 2, guard: 4, from: true
  ]

  ForLineSource: [
    o 'FORIN ExpressionLine'                                      , source: 2
    o 'FOROF ExpressionLine'                                      , source: 2, object: true
    o 'FORIN Expression WHEN ExpressionLine'                      , source: 2, guard: 4
    o 'FORIN ExpressionLine WHEN ExpressionLine'                  , source: 2, guard: 4
    o 'FOROF Expression WHEN ExpressionLine'                      , source: 2, guard: 4, object: true
    o 'FOROF ExpressionLine WHEN ExpressionLine'                  , source: 2, guard: 4, object: true
    o 'FORIN Expression BY ExpressionLine'                        , source: 2, step: 4
    o 'FORIN ExpressionLine BY ExpressionLine'                    , source: 2, step: 4
    o 'FORIN Expression WHEN Expression BY ExpressionLine'        , source: 2, guard: 4, step: 6
    o 'FORIN ExpressionLine WHEN Expression BY ExpressionLine'    , source: 2, guard: 4, step: 6
    o 'FORIN Expression WHEN ExpressionLine BY ExpressionLine'    , source: 2, guard: 4, step: 6
    o 'FORIN ExpressionLine WHEN ExpressionLine BY ExpressionLine', source: 2, guard: 4, step: 6
    o 'FORIN Expression BY Expression WHEN ExpressionLine'        , source: 2, step: 4, guard: 6
    o 'FORIN ExpressionLine BY Expression WHEN ExpressionLine'    , source: 2, step: 4, guard: 6
    o 'FORIN Expression BY ExpressionLine WHEN ExpressionLine'    , source: 2, step: 4, guard: 6
    o 'FORIN ExpressionLine BY ExpressionLine WHEN ExpressionLine', source: 2, step: 4, guard: 6
    o 'FORFROM ExpressionLine'                                    , source: 2, from: true
    o 'FORFROM Expression WHEN ExpressionLine'                    , source: 2, guard: 4, from: true
    o 'FORFROM ExpressionLine WHEN ExpressionLine'                , source: 2, guard: 4, from: true
  ]

  Switch: [
    o 'SWITCH Expression INDENT Whens OUTDENT'               , $ast: '@', subject: 2, cases: 4
    o 'SWITCH ExpressionLine INDENT Whens OUTDENT'           , $ast: '@', subject: 2, cases: 4
    o 'SWITCH Expression INDENT Whens ELSE Block OUTDENT'    , $ast: '@', subject: 2, cases: 4, otherwise: 6, $pos: [5, 6]
    o 'SWITCH ExpressionLine INDENT Whens ELSE Block OUTDENT', $ast: '@', subject: 2, cases: 4, otherwise: 6, $pos: [5, 6]
    o 'SWITCH INDENT Whens OUTDENT'                          , $ast: '@', subject: null, cases: 3
    o 'SWITCH INDENT Whens ELSE Block OUTDENT'               , $ast: '@', subject: null, cases: 3, otherwise: 5, $pos: [4, 5]
  ]

  Whens: [
    o 'When'      , $ary: [1]
    o 'Whens When', $ops: 'array', append: [1, 2]
  ]

  # An individual **When** clause, with action.
  When: [
    o 'LEADING_WHEN SimpleArgs Block'           , $ast: 'SwitchWhen', conditions: 2, body: 3
    o 'LEADING_WHEN SimpleArgs Block TERMINATOR', $ast: 'SwitchWhen', conditions: 2, body: 3, $pos: [1, 3]
  ]

  # The most basic form of *if* is a condition and an action. The followingare broken up like this to avoid ambiguity.
  IfBlock: [
    o 'IF Expression Block'             , $ast: 'If', condition: 2, body: 3, type: 1
    o 'IfBlock ELSE IF Expression Block', $ops: 'if', addElse: [1, {$ast: 'If', condition: 4, body: 5, type: 3, $pos: [3, 5]}]
  ]

  # The full complement of *if* expressions, including postfix one-liner *if* and *unless*.
  If: [
    o 'IfBlock'
    o 'IfBlock ELSE Block'           , $ops: 'if', addElse: [1, 3]
    o 'Statement  POST_IF Expression', $ast: '@', condition: 3, body: [1], type: 2, postfix: true
    o 'Expression POST_IF Expression', $ast: '@', condition: 3, body: [1], type: 2, postfix: true
  ]

  IfBlockLine: [
    o 'IF ExpressionLine Block'                 , $ast: 'If', condition: 2, body: 3, type: 1
    o 'IfBlockLine ELSE IF ExpressionLine Block', $ops: 'if', addElse: [1, {$ast: 'If', condition: 4, body: 5, type: 3, $pos: [3, 5]}]
  ]

  IfLine: [
    o 'IfBlockLine'
    o 'IfBlockLine ELSE Block'           , $ops: 'if', addElse: [1, 3]
    o 'Statement  POST_IF ExpressionLine', $ast: 'If', condition: 3, body: [1], type: 2, postfix: true
    o 'Expression POST_IF ExpressionLine', $ast: 'If', condition: 3, body: [1], type: 2, postfix: true
  ]

  # Arithmetic and logical operators, working on one or more operands.
  # Here they are grouped by order of precedence. The actual precedence rules
  # are defined at the bottom of the page. It would be shorter if we could
  # combine most of these rules into a single generic *Operand OpSymbol Operand*
  # type of rule, but in order to make the precedence binding possible,
  # separate rules are necessary.
  OperationLine: [
    o 'UNARY ExpressionLine', $ast: 'Op', args: [1, 2]
    o 'DO ExpressionLine'   , $ast: 'Op', args: [1, 2]
    o 'DO_IIFE CodeLine'    , $ast: 'Op', args: [1, 2]
  ]

  Operation: [
    o 'UNARY Expression'              , $ast: 'Op', args: [{$use: 1, method: 'toString'}, 2, undefined, undefined], originalOperator: {$use: 1, prop: 'original'}
    o 'DO Expression'                 , $ast: 'Op', args: [1, 2]
    o 'UNARY_MATH Expression'         , $ast: 'Op', args: [1, 2]
    o '- Expression'                  ,{$ast: 'Op', args: ['-', 2]}, prec: 'UNARY_MATH'
    o '+ Expression'                  ,{$ast: 'Op', args: ['+', 2]}, prec: 'UNARY_MATH'

    o 'AWAIT Expression'              , $ast: 'Op', args: [1, 2]
    o 'AWAIT INDENT Object OUTDENT'   , $ast: 'Op', args: [1, 3]

    o '-- SimpleAssignable'           , $ast: 'Op', args: ['--', 2]
    o '++ SimpleAssignable'           , $ast: 'Op', args: ['++', 2]
    o 'SimpleAssignable --'           , $ast: 'Op', args: ['--', 1, null, true]
    o 'SimpleAssignable ++'           , $ast: 'Op', args: ['++', 1, null, true]

    o 'Expression ?'                  , $ast: 'Existence', expression: 1

    o 'Expression +  Expression'      , $ast: 'Op', args: ['+', 1, 3]
    o 'Expression -  Expression'      , $ast: 'Op', args: ['-', 1, 3]

    o 'Expression MATH     Expression', $ast: 'Op', args: [2, 1, 3]
    o 'Expression **       Expression', $ast: 'Op', args: [2, 1, 3]
    o 'Expression SHIFT    Expression', $ast: 'Op', args: [2, 1, 3]
    o 'Expression COMPARE  Expression', $ast: 'Op', args: [{$use: 2, method: 'toString'}, 1, 3, undefined], originalOperator: {$use: 2, prop: 'original'}
    o 'Expression &        Expression', $ast: 'Op', args: [2, 1, 3]
    o 'Expression ^        Expression', $ast: 'Op', args: [2, 1, 3]
    o 'Expression |        Expression', $ast: 'Op', args: [2, 1, 3]
    o 'Expression &&       Expression', $ast: 'Op', args: [{$use: 2, method: 'toString'}, 1, 3, undefined], originalOperator: {$use: 2, prop: 'original'}
    o 'Expression ||       Expression', $ast: 'Op', args: [{$use: 2, method: 'toString'}, 1, 3, undefined], originalOperator: {$use: 2, prop: 'original'}
    o 'Expression BIN?     Expression', $ast: 'Op', args: [2, 1, 3]
    o 'Expression RELATION Expression', $ast: 'Op', args: [{$use: 2, method: 'toString'}, 1, 3, undefined], invertOperator: {$use: 2, prop: 'invert'}

    o 'SimpleAssignable COMPOUND_ASSIGN Expression'               , $ast: 'Assign', variable: 1, value: 3, operator: {$use: 2, method: 'toString'}, originalContext: {$use: 2, prop: 'original'}
    o 'SimpleAssignable COMPOUND_ASSIGN INDENT Expression OUTDENT', $ast: 'Assign', variable: 1, value: 4, operator: {$use: 2, method: 'toString'}, originalContext: {$use: 2, prop: 'original'}
    o 'SimpleAssignable COMPOUND_ASSIGN TERMINATOR Expression'    , $ast: 'Assign', variable: 1, value: 4, operator: {$use: 2, method: 'toString'}, originalContext: {$use: 2, prop: 'original'}
  ]

  DoIife: [
    o 'DO_IIFE Code', $ast: 'Op', args: [1, 2]
  ]

# Precedence here is high to low, but reversed at the end
operators = """
  right       DO_IIFE
  left        . ?. :: ?::
  left        CALL_START CALL_END
  nonassoc    ++ --
  left        ?
  right       UNARY DO
  right       AWAIT
  right       **
  right       UNARY_MATH
  left        MATH
  left        + -
  left        SHIFT
  left        RELATION
  left        COMPARE
  left        &
  left        ^
  left        |
  left        &&
  left        ||
  left        BIN?
  nonassoc    INDENT OUTDENT
  right       YIELD
  right       = : COMPOUND_ASSIGN RETURN THROW EXTENDS
  right       FORIN FOROF FORFROM BY WHEN
  right       IF ELSE FOR WHILE UNTIL LOOP SUPER CLASS IMPORT EXPORT DYNAMIC_IMPORT
  left        POST_IF
""".trim().split('\n').reverse().map (line) -> line.trim().split /\s+/

# Wrapping Up
# -----------

# Add return statements to Root rule actions for proper parser behavior
# (Only for string actions, not CS3 directives)
for own name, alternatives of grammar
  grammar[name] = for alt in alternatives
    # Only add 'return' if it's a string action (not a CS3 directive object)
    if name is 'Root' and typeof alt[1] is 'string'
      alt[1] = "return #{alt[1]}"
    alt

module.exports =
  grammar: grammar # CS3 uses 'grammar' instead of 'bnf'
  operators: operators
