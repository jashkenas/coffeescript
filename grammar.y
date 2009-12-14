class Parser

# Declare tokens produced by the lexer
token IF ELSE THEN
token NEWLINE
token NUMBER
token STRING
token REGEX
token TRUE FALSE NULL
token IDENTIFIER PROPERTY_ACCESS
token CODE PARAM
token NEW RETURN

prechigh
  nonassoc UMINUS NOT '!'
  left     '*' '/' '%'
  left     '+' '-'
  left     '<=' '<' '>' '>='
  right    '==' '!=' IS AINT
  left     '&&' '||' AND OR
  right    '-=' '+=' '/=' '*='
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
  | Variable
  | Call
  | Assign
  | Object
  | Code
  | Operation
  | Array
  | If
  | Return
  | Parenthetical
  ;

  # All tokens that can terminate an expression
  Terminator:
    "\n"
  | ";"
  ;

  # All hard-coded values
  Literal:
    NUMBER                            { result = LiteralNode.new(val[0]) }
  | STRING                            { result = LiteralNode.new(val[0]) }
  | REGEX                             { result = LiteralNode.new(val[0]) }
  | TRUE                              { result = LiteralNode.new(true) }
  | FALSE                             { result = LiteralNode.new(false) }
  | NULL                              { result = LiteralNode.new(nil) }
  ;

  # Assign to a variable
  Assign:
    Variable ":" Expression           { result = AssignNode.new(val[0], val[2]) }
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

  Variable:
    IDENTIFIER                        { result = VariableNode.new(val) }
  | Variable Accessor                 { result = val[0] << val[1] }
  | Call Accessor                     { result = VariableNode.new(val[0], [val[1]]) }
  ;

  Accessor:
    PROPERTY_ACCESS IDENTIFIER        { result = AccessorNode.new(val[1]) }
  | Index                             { result = val[0] }
  ;

  Index:
    "[" Literal "]"                   { result = IndexNode.new(val[1]) }
  ;

  Object:
    "{" "}"                           { result = ObjectNode.new([]) }
  | "{" Terminator "}"                { result = ObjectNode.new([]) }
  | "{" AssignList "}"                { result = ObjectNode.new(val[1]) }
  | "{" Terminator AssignList
        Terminator "}"                { result = ObjectNode.new(val[2]) }
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
  | NEW Invocation                    { result = val[0].new_instance }
  ;

  Invocation:
    Variable "(" ArgList ")"          { result = CallNode.new(val[0], val[2]) }
  ;

  # An Array.
  Array:
    "[" ArgList "]"                   { result = ArrayNode.new(val[1]) }
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
       THEN Expression "."            { result = IfNode.new(val[1], val[3]) }
  | IF Expression Terminator
       Expressions "."                { result = IfNode.new(val[1], val[3]) }
  | IF Expression
       THEN Expression
       ELSE Expression "."            { result = IfNode.new(val[1], val[3], val[5]) }
  | IF Expression Terminator
       Expressions Terminator
       ELSE Expressions "."           { result = IfNode.new(val[1], val[3], val[6]) }
  ;

  Parenthetical:
    "(" Expressions ")"               { result = ParentheticalNode.new(val[1]) }
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