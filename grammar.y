class Parser

# Declare tokens produced by the lexer
token IF ELSE THEN UNLESS
token NUMBER STRING REGEX
token TRUE FALSE NULL
token IDENTIFIER PROPERTY_ACCESS
token CODE PARAM NEW RETURN
token TRY CATCH FINALLY THROW
token BREAK CONTINUE
token FOR IN WHILE
token NEWLINE
token JS

prechigh
  nonassoc UMINUS NOT '!'
  left     '*' '/' '%'
  left     '+' '-'
  left     '<=' '<' '>' '>='
  right    '==' '!=' IS AINT
  left     '&&' '||' AND OR
  left     ':'
  right    '-=' '+=' '/=' '*='
  nonassoc IF
preclow

rule
  # All rules are declared in this format:
  #
  #   RuleName:
  #     OtherRule TOKEN AnotherRule    { code to run when this matches }
  #   | OtherRule                      { ... }
  #   ;
  #
  # In the code section (inside the {...} on the right):
  # - Assign to "result" the value returned by the rule.
  # - Use val[index of expression] to reference expressions on the left.


  # All parsing will end in this rule, being the trunk of the AST.
  Root:
    /* nothing */                     { result = Nodes.new([]) }
  | Expressions                       { result = val[0] }
  ;

  # Any list of expressions or method body, seperated by line breaks.
  Expressions:
    Expression                        { result = Nodes.new(val) }
  | Expressions Terminator Expression { result = val[0] << val[2] }
  | Expressions Terminator            { result = val[0] }
  | Terminator Expressions            { result = val[1] }
  ;

  # All types of expressions in our language
  Expression:
    Literal
  | Value
  | Call
  | Assign
  | Code
  | Operation
  | If
  | Try
  | Throw
  | Return
  | While
  | For
  ;

  # All tokens that can terminate an expression
  Terminator:
    "\n"
  | ";"
  ;

  # All tokens that can serve to begin the second block
  Then:
    THEN
  | Terminator
  ;

  # All hard-coded values
  Literal:
    NUMBER                            { result = LiteralNode.new(val[0]) }
  | STRING                            { result = LiteralNode.new(val[0]) }
  | JS                                { result = LiteralNode.new(val[0]) }
  | REGEX                             { result = LiteralNode.new(val[0]) }
  | TRUE                              { result = LiteralNode.new(true) }
  | FALSE                             { result = LiteralNode.new(false) }
  | NULL                              { result = LiteralNode.new(nil) }
  | BREAK                             { result = LiteralNode.new(val[0]) }
  | CONTINUE                          { result = LiteralNode.new(val[0]) }
  ;

  # Assign to a variable
  Assign:
    Value ":" Expression              { result = AssignNode.new(val[0], val[2]) }
  ;

  # Assignment within an object literal.
  AssignObj:
    IDENTIFIER ":" Expression         { result = AssignNode.new(val[0], val[2], :object) }
  ;

  # A Return statement.
  Return:
    RETURN Expression                 { result = ReturnNode.new(val[1]) }
  ;

  # Arithmetic and logical operators
  # For Ruby's Operator precedence, see:
  # https://www.cs.auckland.ac.nz/references/ruby/ProgrammingRuby/language.html
  Operation:
    '!' Expression                    { result = OpNode.new(val[0], val[1]) }
  | '-' Expression = UMINUS           { result = OpNode.new(val[0], val[1]) }
  | NOT Expression                    { result = OpNode.new(val[0], val[1]) }


  | Expression '*' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '/' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '%' Expression         { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '+' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '-' Expression         { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '<=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '<' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '>' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '>=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '==' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '!=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression IS Expression          { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression AINT Expression        { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '&&' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '||' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression AND Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression OR Expression          { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '-=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '+=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '/=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '*=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '||=' Expression       { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '&&=' Expression       { result = OpNode.new(val[1], val[0], val[2]) }
  ;


  # Method definition
  Code:
    ParamList "=>" Expressions "."    { result = CodeNode.new(val[0], val[2]) }
  | "=>" Expressions "."              { result = CodeNode.new([], val[1]) }
  ;

  ParamList:
    PARAM                             { result = val }
  | ParamList "," PARAM               { result = val[0] << val[2] }
  ;

  Value:
    IDENTIFIER                        { result = ValueNode.new(val) }
  | Array                             { result = ValueNode.new(val) }
  | Object                            { result = ValueNode.new(val) }
  | Parenthetical                     { result = ValueNode.new(val) }
  | Value Accessor                    { result = val[0] << val[1] }
  | Invocation Accessor               { result = ValueNode.new(val[0], [val[1]]) }
  ;

  Accessor:
    PROPERTY_ACCESS IDENTIFIER        { result = AccessorNode.new(val[1]) }
  | Index                             { result = val[0] }
  ;

  Index:
    "[" Literal "]"                   { result = IndexNode.new(val[1]) }
  ;

  Object:
    ObjectStart ObjectEnd             { result = ObjectNode.new([]) }
  | ObjectStart AssignList ObjectEnd  { result = ObjectNode.new(val[1]) }
  ;

  AssignList:
    /* nothing */                     { result = []}
  | AssignObj                         { result = val }
  | AssignList "," AssignObj          { result = val[0] << val[2] }
  | AssignList Terminator AssignObj   { result = val[0] << val[2] }
  ;

  # A method call.
  Call:
    Invocation                        { result = val[0] }
  | NEW Invocation                    { result = val[1].new_instance }
  ;

  Invocation:
    Value ParenStart ArgList ParenEnd { result = CallNode.new(val[0], val[2]) }
  ;

  # An Array.
  Array:
    ArrayStart ArgList ArrayEnd       { result = ArrayNode.new(val[1]) }
  ;

  # A list of arguments to a method call.
  ArgList:
    /* nothing */                     { result = [] }
  | Expression                        { result = val }
  | ArgList "," Expression            { result = val[0] << val[2] }
  | ArgList Terminator Expression     { result = val[0] << val[2] }
  ;

  If:
    IF Expression
       Then Expressions "."           { result = IfNode.new(val[1], val[3]) }
  | IF Expression
       Then Expressions
       ELSE Expressions "."           { result = IfNode.new(val[1], val[3], val[5]) }
  | Expression IF Expression          { result = IfNode.new(val[2], Nodes.new([val[0]])) }
  | Expression UNLESS Expression      { result = IfNode.new(val[2], Nodes.new([val[0]]), nil, :invert) }
  ;

  Try:
    TRY Expressions CATCH IDENTIFIER
      Expressions "."                 { result = TryNode.new(val[1], val[3], val[4]) }
  | TRY Expressions FINALLY
      Expressions "."                 { result = TryNode.new(val[1], nil, nil, val[3]) }
  | TRY Expressions CATCH IDENTIFIER
      Expressions
      FINALLY Expressions "."         { result = TryNode.new(val[1], val[3], val[4], val[6]) }
  ;

  Throw:
    THROW Expression                  { result = ThrowNode.new(val[1]) }
  ;

  Parenthetical:
    ParenStart Expressions ParenEnd   { result = ParentheticalNode.new(val[1]) }
  ;

  While:
    WHILE Expression Then
      Expressions "."                 { result = WhileNode.new(val[1], val[3]) }
  ;

  For:
    Expression FOR IDENTIFIER
      IN Expression "."               { result = ForNode.new(val[0], val[2], val[4]) }
  | Expression FOR IDENTIFIER
      IN Expression
      IF Expression "."               { result = ForNode.new(IfNode.new(val[6], Nodes.new([val[0]])), val[2], val[4]) }
  ;

  ObjectStart:
    "{"                               { result = nil }
  | "{" "\n"                          { result = nil }
  ;

  ObjectEnd:
    "}"                               { result = nil }
  | "\n" "}"                          { result = nil }
  ;

  ParenStart:
    "("                               { result = nil }
  | "(" "\n"                          { result = nil }
  ;

  ParenEnd:
    ")"                               { result = nil }
  | "\n" ")"                          { result = nil }
  ;

  ArrayStart:
    "["                               { result = nil }
  | "[" "\n"                          { result = nil }
  ;

  ArrayEnd:
    "]"                               { result = nil }
  | "\n" "]"                          { result = nil }
  ;

end

---- header
  require "lexer"
  require "nodes"

---- inner
  def parse(code, show_tokens=false)
    # @yydebug = true
    @tokens = Lexer.new.tokenize(code)
    puts @tokens.inspect if show_tokens
    do_parse
  end

  def next_token
    @tokens.shift
  end