(function() {
  var Parser, alt, alternatives, grammar, name, o, operators, token, tokens, unwrap;

  Parser = require('jison').Parser;

  unwrap = /^function\s*\(\)\s*\{\s*return\s*([\s\S]*);\s*\}/;

  o = function(patternString, action, options) {
    var match;
    patternString = patternString.replace(/\s{2,}/g, ' ');
    if (!action) return [patternString, '$$ = $1;', options];
    action = (match = unwrap.exec(action)) ? match[1] : "(" + action + "())";
    action = action.replace(/\bnew /g, '$&yy.');
    action = action.replace(/\$L\(([\w_$]+)\)/g, 'setLocation(new yy.Location(@$1))');
    action = action.replace(/\$L/g, 'setLocation(new yy.Location(@1))');
    action = action.replace(/\b(?:Block\.wrap|extend)\b/g, 'yy.$&');
    return [patternString, "$$ = " + action + ";", options];
  };

  grammar = {
    Root: [
      o('', function() {
        return new Block;
      }), o('Body'), o('Block TERMINATOR')
    ],
    Body: [
      o('Line', function() {
        return Block.wrap([$1]).$L;
      }), o('Body TERMINATOR Line', function() {
        return $1.push($3);
      }), o('Body TERMINATOR')
    ],
    Line: [o('Expression'), o('Statement')],
    Statement: [
      o('Return'), o('Comment'), o('STATEMENT', function() {
        return new Literal($1).$L;
      })
    ],
    Expression: [o('Value'), o('Invocation'), o('Code'), o('Operation'), o('Assign'), o('If'), o('Try'), o('While'), o('For'), o('Switch'), o('Class'), o('Throw')],
    Block: [
      o('INDENT OUTDENT', function() {
        return new Block().$L;
      }), o('INDENT Body OUTDENT', function() {
        return $2;
      })
    ],
    Identifier: [
      o('IDENTIFIER', function() {
        return new Literal($1).$L;
      })
    ],
    AlphaNumeric: [
      o('NUMBER', function() {
        return new Literal($1).$L;
      }), o('STRING', function() {
        return new Literal($1).$L;
      })
    ],
    Literal: [
      o('AlphaNumeric'), o('JS', function() {
        return new Literal($1).$L;
      }), o('REGEX', function() {
        return new Literal($1).$L;
      }), o('DEBUGGER', function() {
        return new Literal($1).$L;
      }), o('BOOL', function() {
        var val;
        val = new Literal($1).$L;
        if ($1 === 'undefined') val.isUndefined = true;
        return val;
      })
    ],
    Assign: [
      o('Assignable = Expression', function() {
        return new Assign($1, $3).$L;
      }), o('Assignable = TERMINATOR Expression', function() {
        return new Assign($1, $4).$L;
      }), o('Assignable = INDENT Expression OUTDENT', function() {
        return new Assign($1, $4).$L;
      })
    ],
    AssignObj: [
      o('ObjAssignable', function() {
        return new Value($1).$L;
      }), o('ObjAssignable : Expression', function() {
        return new Assign(new Value($1).$L, $3, 'object').$L;
      }), o('ObjAssignable :\
       INDENT Expression OUTDENT', function() {
        return new Assign(new Value($1).$L, $4, 'object').$L;
      }), o('Comment')
    ],
    ObjAssignable: [o('Identifier'), o('AlphaNumeric'), o('ThisProperty')],
    Return: [
      o('RETURN Expression', function() {
        return new Return($2).$L;
      }), o('RETURN', function() {
        return new Return().$L;
      })
    ],
    Comment: [
      o('HERECOMMENT', function() {
        return new Comment($1).$L;
      })
    ],
    Code: [
      o('PARAM_START ParamList PARAM_END FuncGlyph Block', function() {
        return new Code($2, $5, $4).$L;
      }), o('FuncGlyph Block', function() {
        return new Code([], $2, $1).$L;
      })
    ],
    FuncGlyph: [
      o('->', function() {
        return 'func';
      }), o('=>', function() {
        return 'boundfunc';
      })
    ],
    OptComma: [o(''), o(',')],
    ParamList: [
      o('', function() {
        return [];
      }), o('Param', function() {
        return [$1];
      }), o('ParamList , Param', function() {
        return $1.concat($3);
      })
    ],
    Param: [
      o('ParamVar', function() {
        return new Param($1).$L;
      }), o('ParamVar ...', function() {
        return new Param($1, null, true).$L;
      }), o('ParamVar = Expression', function() {
        return new Param($1, $3).$L;
      })
    ],
    ParamVar: [o('Identifier'), o('ThisProperty'), o('Array'), o('Object')],
    Splat: [
      o('Expression ...', function() {
        return new Splat($1).$L;
      })
    ],
    SimpleAssignable: [
      o('Identifier', function() {
        return new Value($1).$L;
      }), o('Value Accessor', function() {
        return $1.add($2);
      }), o('Invocation Accessor', function() {
        return new Value($1, [].concat($2)).$L;
      }), o('ThisProperty')
    ],
    Assignable: [
      o('SimpleAssignable'), o('Array', function() {
        return new Value($1).$L;
      }), o('Object', function() {
        return new Value($1).$L;
      })
    ],
    Value: [
      o('Assignable'), o('Literal', function() {
        return new Value($1).$L;
      }), o('Parenthetical', function() {
        return new Value($1).$L;
      }), o('Range', function() {
        return new Value($1).$L;
      }), o('This')
    ],
    Accessor: [
      o('.  Identifier', function() {
        return new Access($2).$L(2);
      }), o('?. Identifier', function() {
        return new Access($2, 'soak').$L(2);
      }), o(':: Identifier', function() {
        return [new Access(new Literal('prototype')).$L, new Access($2).$L(2)];
      }), o('::', function() {
        return new Access(new Literal('prototype').$L);
      }), o('Index')
    ],
    Index: [
      o('INDEX_START IndexValue INDEX_END', function() {
        return $2;
      }), o('INDEX_SOAK  Index', function() {
        return extend($2, {
          soak: true
        });
      })
    ],
    IndexValue: [
      o('Expression', function() {
        return new Index($1).$L;
      }), o('Slice', function() {
        return new Slice($1).$L;
      })
    ],
    Object: [
      o('{ AssignList OptComma }', function() {
        return new Obj($2, $1.generated).$L;
      })
    ],
    AssignList: [
      o('', function() {
        return [];
      }), o('AssignObj', function() {
        return [$1];
      }), o('AssignList , AssignObj', function() {
        return $1.concat($3);
      }), o('AssignList OptComma TERMINATOR AssignObj', function() {
        return $1.concat($4);
      }), o('AssignList OptComma INDENT AssignList OptComma OUTDENT', function() {
        return $1.concat($4);
      })
    ],
    Class: [
      o('CLASS', function() {
        return new Class().$L;
      }), o('CLASS Block', function() {
        return new Class(null, null, $2).$L;
      }), o('CLASS EXTENDS Expression', function() {
        return new Class(null, $3).$L;
      }), o('CLASS EXTENDS Expression Block', function() {
        return new Class(null, $3, $4).$L;
      }), o('CLASS SimpleAssignable', function() {
        return new Class($2).$L;
      }), o('CLASS SimpleAssignable Block', function() {
        return new Class($2, null, $3).$L;
      }), o('CLASS SimpleAssignable EXTENDS Expression', function() {
        return new Class($2, $4).$L;
      }), o('CLASS SimpleAssignable EXTENDS Expression Block', function() {
        return new Class($2, $4, $5).$L;
      })
    ],
    Invocation: [
      o('Value OptFuncExist Arguments', function() {
        return new Call($1, $3, $2).$L;
      }), o('Invocation OptFuncExist Arguments', function() {
        return new Call($1, $3, $2).$L;
      }), o('SUPER', function() {
        return new Call('super', [new Splat(new Literal('arguments'))]).$L;
      }), o('SUPER Arguments', function() {
        return new Call('super', $2).$L;
      })
    ],
    OptFuncExist: [
      o('', function() {
        return false;
      }), o('FUNC_EXIST', function() {
        return true;
      })
    ],
    Arguments: [
      o('CALL_START CALL_END', function() {
        return [];
      }), o('CALL_START ArgList OptComma CALL_END', function() {
        return $2;
      })
    ],
    This: [
      o('THIS', function() {
        return new Value(new Literal('this').$L).$L;
      }), o('@', function() {
        return new Value(new Literal('this').$L).$L;
      })
    ],
    ThisProperty: [
      o('@ Identifier', function() {
        return new Value(new Literal('this').$L, [new Access($2).$L(2)], 'this').$L;
      })
    ],
    Array: [
      o('[ ]', function() {
        return new Arr([]).$L;
      }), o('[ ArgList OptComma ]', function() {
        return new Arr($2).$L;
      })
    ],
    RangeDots: [
      o('..', function() {
        return 'inclusive';
      }), o('...', function() {
        return 'exclusive';
      })
    ],
    Range: [
      o('[ Expression RangeDots Expression ]', function() {
        return new Range($2, $4, $3).$L;
      })
    ],
    Slice: [
      o('Expression RangeDots Expression', function() {
        return new Range($1, $3, $2).$L;
      }), o('Expression RangeDots', function() {
        return new Range($1, null, $2).$L;
      }), o('RangeDots Expression', function() {
        return new Range(null, $2, $1).$L;
      }), o('RangeDots', function() {
        return new Range(null, null, $1).$L;
      })
    ],
    ArgList: [
      o('Arg', function() {
        return [$1];
      }), o('ArgList , Arg', function() {
        return $1.concat($3);
      }), o('ArgList OptComma TERMINATOR Arg', function() {
        return $1.concat($4);
      }), o('INDENT ArgList OptComma OUTDENT', function() {
        return $2;
      }), o('ArgList OptComma INDENT ArgList OptComma OUTDENT', function() {
        return $1.concat($4);
      })
    ],
    Arg: [o('Expression'), o('Splat')],
    SimpleArgs: [
      o('Expression'), o('SimpleArgs , Expression', function() {
        return [].concat($1, $3);
      })
    ],
    Try: [
      o('TRY Block', function() {
        return new Try($2).$L;
      }), o('TRY Block Catch', function() {
        return new Try($2, $3[0], $3[1]).$L;
      }), o('TRY Block FINALLY Block', function() {
        return new Try($2, null, null, $4).$L;
      }), o('TRY Block Catch FINALLY Block', function() {
        return new Try($2, $3[0], $3[1], $5).$L;
      })
    ],
    Catch: [
      o('CATCH Identifier Block', function() {
        return [$2, $3];
      })
    ],
    Throw: [
      o('THROW Expression', function() {
        return new Throw($2).$L;
      })
    ],
    Parenthetical: [
      o('( Body )', function() {
        return new Parens($2).$L;
      }), o('( INDENT Body OUTDENT )', function() {
        return new Parens($3).$L;
      })
    ],
    WhileSource: [
      o('WHILE Expression', function() {
        return new While($2).$L;
      }), o('WHILE Expression WHEN Expression', function() {
        return new While($2, {
          guard: $4
        }).$L;
      }), o('UNTIL Expression', function() {
        return new While($2, {
          invert: true
        }).$L;
      }), o('UNTIL Expression WHEN Expression', function() {
        return new While($2, {
          invert: true,
          guard: $4
        }).$L;
      })
    ],
    While: [
      o('WhileSource Block', function() {
        return $1.addBody($2);
      }), o('Statement  WhileSource', function() {
        return $2.addBody(Block.wrap([$1]));
      }), o('Expression WhileSource', function() {
        return $2.addBody(Block.wrap([$1]));
      }), o('Loop', function() {
        return $1;
      })
    ],
    Loop: [
      o('LOOP Block', function() {
        return new While(new Literal('true')).$L.addBody($2);
      }), o('LOOP Expression', function() {
        return new While(new Literal('true')).$L.addBody(Block.wrap([$2]));
      })
    ],
    For: [
      o('Statement  ForBody', function() {
        return new For($1, $2).$L;
      }), o('Expression ForBody', function() {
        return new For($1, $2).$L;
      }), o('ForBody    Block', function() {
        return new For($2, $1).$L;
      })
    ],
    ForBody: [
      o('FOR Range', function() {
        return {
          source: new Value($2).$L
        };
      }), o('ForStart ForSource', function() {
        $2.own = $1.own;
        $2.name = $1[0];
        $2.index = $1[1];
        return $2;
      })
    ],
    ForStart: [
      o('FOR ForVariables', function() {
        return $2;
      }), o('FOR OWN ForVariables', function() {
        $3.own = true;
        return $3;
      })
    ],
    ForValue: [
      o('Identifier'), o('Array', function() {
        return new Value($1).$L;
      }), o('Object', function() {
        return new Value($1).$L;
      })
    ],
    ForVariables: [
      o('ForValue', function() {
        return [$1];
      }), o('ForValue , ForValue', function() {
        return [$1, $3];
      })
    ],
    ForSource: [
      o('FORIN Expression', function() {
        return {
          source: $2
        };
      }), o('FOROF Expression', function() {
        return {
          source: $2,
          object: true
        };
      }), o('FORIN Expression WHEN Expression', function() {
        return {
          source: $2,
          guard: $4
        };
      }), o('FOROF Expression WHEN Expression', function() {
        return {
          source: $2,
          guard: $4,
          object: true
        };
      }), o('FORIN Expression BY Expression', function() {
        return {
          source: $2,
          step: $4
        };
      }), o('FORIN Expression WHEN Expression BY Expression', function() {
        return {
          source: $2,
          guard: $4,
          step: $6
        };
      }), o('FORIN Expression BY Expression WHEN Expression', function() {
        return {
          source: $2,
          step: $4,
          guard: $6
        };
      })
    ],
    Switch: [
      o('SWITCH Expression INDENT Whens OUTDENT', function() {
        return new Switch($2, $4).$L;
      }), o('SWITCH Expression INDENT Whens ELSE Block OUTDENT', function() {
        return new Switch($2, $4, $6).$L;
      }), o('SWITCH INDENT Whens OUTDENT', function() {
        return new Switch(null, $3).$L;
      }), o('SWITCH INDENT Whens ELSE Block OUTDENT', function() {
        return new Switch(null, $3, $5).$L;
      })
    ],
    Whens: [
      o('When'), o('Whens When', function() {
        return $1.concat($2);
      })
    ],
    When: [
      o('LEADING_WHEN SimpleArgs Block', function() {
        return [[$2, $3]];
      }), o('LEADING_WHEN SimpleArgs Block TERMINATOR', function() {
        return [[$2, $3]];
      })
    ],
    IfBlock: [
      o('IF Expression Block', function() {
        return new If($2, $3, {
          type: $1
        }).$L;
      }), o('IfBlock ELSE IF Expression Block', function() {
        return $1.addElse(new If($4, $5, {
          type: $3
        }));
      })
    ],
    If: [
      o('IfBlock'), o('IfBlock ELSE Block', function() {
        return $1.addElse($3);
      }), o('Statement  POST_IF Expression', function() {
        return new If($3, Block.wrap([$1]).$L, {
          type: $2,
          statement: true
        }).$L(2);
      }), o('Expression POST_IF Expression', function() {
        return new If($3, Block.wrap([$1]).$L, {
          type: $2,
          statement: true
        }).$L(2);
      })
    ],
    Operation: [
      o('UNARY Expression', function() {
        return new Op($1, $2).$L;
      }), o('-     Expression', (function() {
        return new Op('-', $2).$L;
      }), {
        prec: 'UNARY'
      }), o('+     Expression', (function() {
        return new Op('+', $2).$L;
      }), {
        prec: 'UNARY'
      }), o('-- SimpleAssignable', function() {
        return new Op('--', $2).$L;
      }), o('++ SimpleAssignable', function() {
        return new Op('++', $2).$L;
      }), o('SimpleAssignable --', function() {
        return new Op('--', $1, null, true).$L;
      }), o('SimpleAssignable ++', function() {
        return new Op('++', $1, null, true).$L;
      }), o('Expression ?', function() {
        return new Existence($1).$L;
      }), o('Expression +  Expression', function() {
        return new Op('+', $1, $3).$L;
      }), o('Expression -  Expression', function() {
        return new Op('-', $1, $3).$L;
      }), o('Expression MATH     Expression', function() {
        return new Op($2, $1, $3).$L;
      }), o('Expression SHIFT    Expression', function() {
        return new Op($2, $1, $3).$L;
      }), o('Expression COMPARE  Expression', function() {
        return new Op($2, $1, $3).$L;
      }), o('Expression LOGIC    Expression', function() {
        return new Op($2, $1, $3).$L;
      }), o('Expression RELATION Expression', function() {
        if ($2.charAt(0) === '!') {
          return new Op($2.slice(1), $1, $3).invert().$L;
        } else {
          return new Op($2, $1, $3).$L;
        }
      }), o('SimpleAssignable COMPOUND_ASSIGN\
       Expression', function() {
        return new Assign($1, $3, $2).$L;
      }), o('SimpleAssignable COMPOUND_ASSIGN\
       INDENT Expression OUTDENT', function() {
        return new Assign($1, $4, $2).$L;
      }), o('SimpleAssignable EXTENDS Expression', function() {
        return new Extends($1, $3).$L;
      })
    ]
  };

  operators = [['left', '.', '?.', '::'], ['left', 'CALL_START', 'CALL_END'], ['nonassoc', '++', '--'], ['left', '?'], ['right', 'UNARY'], ['left', 'MATH'], ['left', '+', '-'], ['left', 'SHIFT'], ['left', 'RELATION'], ['left', 'COMPARE'], ['left', 'LOGIC'], ['nonassoc', 'INDENT', 'OUTDENT'], ['right', '=', ':', 'COMPOUND_ASSIGN', 'RETURN', 'THROW', 'EXTENDS'], ['right', 'FORIN', 'FOROF', 'BY', 'WHEN'], ['right', 'IF', 'ELSE', 'FOR', 'WHILE', 'UNTIL', 'LOOP', 'SUPER', 'CLASS'], ['right', 'POST_IF']];

  tokens = [];

  for (name in grammar) {
    alternatives = grammar[name];
    grammar[name] = (function() {
      var _i, _j, _len, _len2, _ref, _results;
      _results = [];
      for (_i = 0, _len = alternatives.length; _i < _len; _i++) {
        alt = alternatives[_i];
        _ref = alt[0].split(' ');
        for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
          token = _ref[_j];
          if (!grammar[token]) tokens.push(token);
        }
        if (name === 'Root') alt[1] = "return " + alt[1];
        _results.push(alt);
      }
      return _results;
    })();
  }

  exports.parser = new Parser({
    tokens: tokens.join(' '),
    bnf: grammar,
    operators: operators.reverse(),
    startSymbol: 'Root'
  });

}).call(this);
