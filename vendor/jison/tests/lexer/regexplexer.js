var RegExpLexer = require("../setup").RegExpLexer,
    assert = require("assert"),
    jsDump = require("test/jsdump").jsDump;

exports["test basic matchers"] = function() {
    var dict = {
        rules: [
           ["x", "return 'X';" ],
           ["y", "return 'Y';" ],
           ["$", "return 'EOF';" ]
       ]
    };

    var input = "xxyx";

    var lexer = new RegExpLexer(dict, input);
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "Y");
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "EOF");
};

exports["test set input after"] = function() {
    var dict = {
        rules: [
           ["x", "return 'X';" ],
           ["y", "return 'Y';" ],
           ["$", "return 'EOF';" ]
       ]
    };

    var input = "xxyx";

    var lexer = new RegExpLexer(dict);
    lexer.setInput(input);

    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "Y");
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "EOF");
};

exports["test unrecognized char"] = function() {
    var dict = {
        rules: [
           ["x", "return 'X';" ],
           ["y", "return 'Y';" ],
           ["$", "return 'EOF';" ]
       ]
    };

    var input = "xa";

    var lexer = new RegExpLexer(dict, input);
    assert.equal(lexer.lex(), "X");
    assert["throws"](function(){lexer.lex()}, "bad char");
};

exports["test macro"] = function() {
    var dict = {
        macros: {
            "digit": "[0-9]"
        },
        rules: [
           ["x", "return 'X';" ],
           ["y", "return 'Y';" ],
           ["{digit}+", "return 'NAT';" ],
           ["$", "return 'EOF';" ]
       ]
    };

    var input = "x12234y42";

    var lexer = new RegExpLexer(dict, input);
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "NAT");
    assert.equal(lexer.lex(), "Y");
    assert.equal(lexer.lex(), "NAT");
    assert.equal(lexer.lex(), "EOF");
};

exports["test action include"] = function() {
    var dict = {
        rules: [
           ["x", "return included ? 'Y' : 'N';" ],
           ["$", "return 'EOF';" ]
       ],
       actionInclude: "var included = true;"
    };

    var input = "x";

    var lexer = new RegExpLexer(dict, input);
    assert.equal(lexer.lex(), "Y");
    assert.equal(lexer.lex(), "EOF");
};

exports["test ignored"] = function() {
    var dict = {
        rules: [
           ["x", "return 'X';" ],
           ["y", "return 'Y';" ],
           ["\\s+", "/* skip whitespace */" ],
           ["$", "return 'EOF';" ]
       ]
    };

    var input = "x x   y x";

    var lexer = new RegExpLexer(dict, input);
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "Y");
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "EOF");
};

exports["test dissambiguate"] = function() {
    var dict = {
        rules: [
           ["for\\b", "return 'FOR';" ],
           ["if\\b", "return 'IF';" ],
           ["[a-z]+", "return 'IDENTIFIER';" ],
           ["\\s+", "/* skip whitespace */" ],
           ["$", "return 'EOF';" ]
       ]
    };

    var input = "if forever for for";

    var lexer = new RegExpLexer(dict, input);
    assert.equal(lexer.lex(), "IF");
    assert.equal(lexer.lex(), "IDENTIFIER");
    assert.equal(lexer.lex(), "FOR");
    assert.equal(lexer.lex(), "FOR");
    assert.equal(lexer.lex(), "EOF");
};

exports["test yytext overwrite"] = function() {
    var dict = {
        rules: [
           ["x", "yytext = 'hi der'; return 'X';" ]
       ]
    };

    var input = "x";

    var lexer = new RegExpLexer(dict, input);
    lexer.lex();
    assert.equal(lexer.yytext, "hi der");
};

exports["test yylineno"] = function() {
    var dict = {
        rules: [
           ["\\s+", "/* skip whitespace */" ],
           ["x", "return 'x';" ],
           ["y", "return 'y';" ]
       ]
    };

    var input = "x\nxy\n\n\nx";

    var lexer = new RegExpLexer(dict, input);
    assert.equal(lexer.yylineno, 0);
    assert.equal(lexer.lex(), "x");
    assert.equal(lexer.lex(), "x");
    assert.equal(lexer.yylineno, 1);
    assert.equal(lexer.lex(), "y");
    assert.equal(lexer.yylineno, 1);
    assert.equal(lexer.lex(), "x");
    assert.equal(lexer.yylineno, 4);
};

exports["test more()"] = function() {
    var dict = {
        rules: [
           ["x", "return 'X';" ],
           ['"[^"]*', function(){
               if(yytext.charAt(yyleng-1) == '\\') {
                   this.more();
               } else {
                   yytext += this.input(); // swallow end quote
                   return "STRING";
               }
            } ],
           ["$", "return 'EOF';" ]
       ]
    };

    var input = 'x"fgjdrtj\\"sdfsdf"x';

    var lexer = new RegExpLexer(dict, input);
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "STRING");
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "EOF");
};

exports["test defined token returns"] = function() {
    var tokens = {"2":"X", "3":"Y", "4":"EOF"};
    var dict = {
        rules: [
           ["x", "return 'X';" ],
           ["y", "return 'Y';" ],
           ["$", "return 'EOF';" ]
       ]
    };

    var input = "xxyx";

    var lexer = new RegExpLexer(dict, input, tokens);

    assert.equal(lexer.lex(), 2);
    assert.equal(lexer.lex(), 2);
    assert.equal(lexer.lex(), 3);
    assert.equal(lexer.lex(), 2);
    assert.equal(lexer.lex(), 4);
};

exports["test module generator"] = function() {
    var dict = {
        rules: [
           ["x", "return 'X';" ],
           ["y", "return 'Y';" ],
           ["$", "return 'EOF';" ]
       ]
    };

    var input = "xxyx";

    var lexer_ = new RegExpLexer(dict);
    var lexerSource = lexer_.generateModule();
    eval(lexerSource);
    lexer.setInput(input);
    
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "Y");
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "EOF");
};

exports["test generator with more complex lexer"] = function() {
    var dict = {
        rules: [
           ["x", "return 'X';" ],
           ['"[^"]*', function(){
               if(yytext.charAt(yyleng-1) == '\\') {
                   this.more();
               } else {
                   yytext += this.input(); // swallow end quote
                   return "STRING";
               }
            } ],
           ["$", "return 'EOF';" ]
       ]
    };

    var input = 'x"fgjdrtj\\"sdfsdf"x';

    var lexer_ = new RegExpLexer(dict);
    var lexerSource = lexer_.generateModule();
    eval(lexerSource);
    lexer.setInput(input);

    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "STRING");
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "EOF");
};

exports["test commonjs module generator"] = function() {
    var dict = {
        rules: [
           ["x", "return 'X';" ],
           ["y", "return 'Y';" ],
           ["$", "return 'EOF';" ]
       ]
    };

    var input = "xxyx";

    var lexer_ = new RegExpLexer(dict);
    var lexerSource = lexer_.generateCommonJSModule();
    var exports = {};
    eval(lexerSource);
    exports.lexer.setInput(input);
    
    assert.equal(exports.lex(), "X");
    assert.equal(exports.lex(), "X");
    assert.equal(exports.lex(), "Y");
    assert.equal(exports.lex(), "X");
    assert.equal(exports.lex(), "EOF");
};

exports["test DJ lexer"] = function() {
    var dict = {
    "lex": {
        "macros": {
            "digit": "[0-9]",
            "id": "[a-zA-Z][a-zA-Z0-9]*" 
        },

        "rules": [
            ["//.*",       "/* ignore comment */"],
            ["main\\b",     "return 'MAIN';"],
            ["class\\b",    "return 'CLASS';"],
            ["extends\\b",  "return 'EXTENDS';"],
            ["nat\\b",      "return 'NATTYPE';"],
            ["if\\b",       "return 'IF';"],
            ["else\\b",     "return 'ELSE';"],
            ["for\\b",      "return 'FOR';"],
            ["printNat\\b", "return 'PRINTNAT';"],
            ["readNat\\b",  "return 'READNAT';"],
            ["this\\b",     "return 'THIS';"],
            ["new\\b",      "return 'NEW';"],
            ["var\\b",      "return 'VAR';"],
            ["null\\b",     "return 'NUL';"],
            ["{digit}+",   "return 'NATLITERAL';"],
            ["{id}",       "return 'ID';"],
            ["==",         "return 'EQUALITY';"],
            ["=",          "return 'ASSIGN';"],
            ["\\+",        "return 'PLUS';"],
            ["-",          "return 'MINUS';"],
            ["\\*",        "return 'TIMES';"],
            [">",          "return 'GREATER';"],
            ["\\|\\|",     "return 'OR';"],
            ["!",          "return 'NOT';"],
            ["\\.",        "return 'DOT';"],
            ["\\{",        "return 'LBRACE';"],
            ["\\}",        "return 'RBRACE';"],
            ["\\(",        "return 'LPAREN';"],
            ["\\)",        "return 'RPAREN';"],
            [";",          "return 'SEMICOLON';"],
            ["\\s+",       "/* skip whitespace */"],
            [".",          "print('Illegal character');throw 'Illegal character';"],
            ["$",          "return 'ENDOFFILE';"]
        ]
    }
};

    var input = "class Node extends Object { \
                      var nat value    var nat value;\
                      var Node next;\
                      var nat index;\
                    }\
\
                    class List extends Object {\
                      var Node start;\
\
                      Node prepend(Node startNode) {\
                        startNode.next = start;\
                        start = startNode;\
                      }\
\
                      nat find(nat index) {\
                        var nat value;\
                        var Node node;\
\
                        for(node = start;!(node == null);node = node.next){\
                          if(node.index == index){\
                            value = node.value;\
                          } else { 0; };\
                        };\
\
                        value;\
                      }\
                    }\
\
                    main {\
                      var nat index;\
                      var nat value;\
                      var List list;\
                      var Node startNode;\
\
                      index = readNat();\
                      list = new List;\
\
                      for(0;!(index==0);0){\
                        value = readNat();\
                        startNode = new Node;\
                        startNode.index = index;\
                        startNode.value = value;\
                        list.prepend(startNode);\
                        index = readNat();\
                      };\
\
                      index = readNat();\
\
                      for(0;!(index==0);0){\
                        printNat(list.find(index));\
                        index = readNat();\
                      };\
                    }";

    var lexer = new RegExpLexer(dict.lex);
    lexer.setInput(input);
    var tok;
    while (tok = lexer.lex()) {
        assert.equal(typeof tok, "string");
    }
};

exports["test instantiation from string"] = function() {
    var dict = "%%\n'x' {return 'X';}\n'y' {return 'Y';}\n<<EOF>> {return 'EOF';}";
        
    var input = "x";

    var lexer = new RegExpLexer(dict);
    lexer.setInput(input);
    
    assert.equal(lexer.lex(), "X");
    assert.equal(lexer.lex(), "EOF");
};
