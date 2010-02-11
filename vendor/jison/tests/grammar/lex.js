var Jison = require("../setup").Jison,
    Lexer = require("../setup").Lexer,
    bnf = require("../../lib/jison/bnf"),
    assert = require("assert");

exports["test Lex parser"] = function () {
    var lex = {
        "rules": [
            ["\\n+", "yy.freshLine = true;"],
            ["\\s+", "yy.freshLine = false;"],
            ["y\\{[^}]*\\}", "yytext = yytext.substr(2, yytext.length-3);return 'ACTION';"],
            ["[a-zA-Z_][a-zA-Z0-9_-]*", "return 'NAME';"],
            ["\"(?:[^\"]|\\\\\")*\"", "return 'STRING_LIT';"],
            ["'(?:[^']|\\\\')*'", "return 'STRING_LIT';"],
            ["\\|", "return '|';"],
            ["\\[(?:[^\\]]|\\\\])*\\]", "return 'ANY_GROUP_REGEX';"],
            ["\\(", "return '(';"],
            ["\\)", "return ')';"],
            ["\\+", "return '+';"],
            ["\\*", "return '*';"],
            ["\\?", "return '?';"],
            ["\\^", "return '^';"],
            ["\\/", "return '/';"],
            ["\\$", "return '$';"],
            ["%%", "return '%%';"],
            ["\\{\\d+(?:,\\s?\\d+\\|,)?\\}", "return 'RANGE_REGEX';"],
            ["(?=\\{)", "if(yy.freshLine){this.input('{');return '{';} else this.unput('y');"],
            ["\\}", "return '}';"],
            ["%\\{(?:.|\\n)*?\\}%", "yytext = yytext.substr(2, yytext.length-4);return 'ACTION';"],
            [".", "/* ignore bad characters */"],
            ["$", "return 'EOF';"]
        ]
    };

    var fs = require("file");
    var grammar = bnf.parse(fs.path(fs.dirname(module.id))
            .join('lex.jison')
            .read({charset: "utf-8"}));

    var parser = new Jison.Parser(grammar);
    parser.lexer = new Lexer(lex);

    function encodeRE (s) { return s.replace(/([.*+?^${}()|[\]\/\\])/g, '\\$1'); }

    parser.yy = {
        prepareString: function (s) {
            s = encodeRE(s);
            if (s.match(/\w|\d$/)) {
                s = s+"\\b";
            }
            return s;
        }
    };

    var result = parser.parse('D [0-9]\nID [a-zA-Z][a-zA-Z0-9]+\n%%\n\n{D}"ohh\nai" {print(9);}\n"}"  {stuff}');
    assert.ok(result, "parse bnf production");
};

