var Jison = require("../setup").Jison,
    Lexer = require("../setup").Lexer,
    assert = require("assert");

exports["test 0+0 grammar"] = function () {
    var lexData2 = {
        rules: [
           ["0", "return 'ZERO';"],
           ["\\+", "return 'PLUS';"]
        ]
    };
    var grammar = {
        tokens: [ "ZERO", "PLUS"],
        startSymbol: "E",
        bnf: {
            "E" :[ "E PLUS T",
                   "T"      ],
            "T" :[ "ZERO" ]
        }
    };

    var parser = new Jison.Parser(grammar, {type: "lalr"});
    parser.lexer = new Lexer(lexData2);

    assert.ok(parser.parse("0+0+0"), "parse");
    assert.ok(parser.parse("0"), "parse single 0");

    assert["throws"](function () {parser.parse("+")}, "throws parse error on invalid");
};

exports["test xx nullable grammar"] = function () {
    var lexData = {
        rules: [
           ["x", "return 'x';"]
        ]
    };
    var grammar = {
        tokens: [ 'x' ],
        startSymbol: "A",
        bnf: {
            "A" :[ 'A x',
                   ''      ]
        }
    };

    var parser = new Jison.Parser(grammar, {type: "lalr"});
    parser.lexer = new Lexer(lexData);

    assert.ok(parser.parse("xxx"), "parse");
    assert.ok(parser.parse("x"), "parse single x");
    assert["throws"](function (){parser.parse("+");}, "throws parse error on invalid");
};

exports["test LALR algorithm from Bermudez, Logothetis"] = function () {
    var lexData = {
        rules: [
           ["a", "return 'a';"],
           ["b", "return 'b';"],
           ["c", "return 'c';"],
           ["d", "return 'd';"],
           ["g", "return 'g';"]
        ]
    };
    var grammar = {
        "tokens": "a b c d g",
        "startSymbol": "S",
        "bnf": {
            "S" :[ "a g d",
                   "a A c",
                   "b A d",
                   "b g c" ],
            "A" :[ "B" ],
            "B" :[ "g" ]
        }
    };

    var parser = new Jison.Parser(grammar, {type: "lalr"});
    parser.lexer = new Lexer(lexData);
    assert.ok(parser.parse("agd"));
    assert.ok(parser.parse("agc"));
    assert.ok(parser.parse("bgd"));
    assert.ok(parser.parse("bgc"));
};

exports["test basic JSON grammar"] = function () {
    var grammar = {
        "lex": {
            "macros": {
                "digit": "[0-9]",
                "esc": "\\\\",
                "int": "-?(?:[0-9]|[1-9][0-9]+)",
                "exp": "(?:[eE][-+]?[0-9]+)",
                "frac": "(?:\\.[0-9]+)"
            },
            "rules": [
                ["\\s+", "/* skip whitespace */"],
                ["{int}{frac}?{exp}?\\b", "return 'NUMBER';"],
                ["\"(?:{esc}[\"bfnrt/{esc}]|{esc}u[a-fA-F0-9]{4}|[^\"{esc}])*\"", "yytext = yytext.substr(1,yyleng-2); return 'STRING';"],
                ["\\{", "return '{'"],
                ["\\}", "return '}'"],
                ["\\[", "return '['"],
                ["\\]", "return ']'"],
                [",", "return ','"],
                [":", "return ':'"],
                ["true\\b", "return 'TRUE'"],
                ["false\\b", "return 'FALSE'"],
                ["null\\b", "return 'NULL'"]
            ]
        },

        "tokens": "STRING NUMBER { } [ ] , : TRUE FALSE NULL",
        "bnf": {
            "JsonThing": [ "JsonObject",
                           "JsonArray" ],

            "JsonObject": [ "{ JsonPropertyList }" ],

            "JsonPropertyList": [ "JsonProperty",
                                  "JsonPropertyList , JsonProperty" ],

            "JsonProperty": [ "StringLiteral : JsonValue" ],

            "JsonArray": [ "[ JsonValueList ]" ],

            "JsonValueList": [ "JsonValue",
                               "JsonValueList , JsonValue" ],

            "JsonValue": [ "StringLiteral",
                           "NumericalLiteral",
                           "JsonObject",
                           "JsonArray",
                           "TRUE",
                           "FALSE",
                           "NULL" ],

            "StringLiteral": [ "STRING" ],

            "NumericalLiteral": [ "NUMBER" ]
        },
    };

    var source = '{"foo": "Bar", "hi": 42, "array": [1,2,3.004, -4.04e-4], "false": false, "true":true, "null": null, "obj": {"ha":"ho"}, "string": "str\\ting\\"sgfg" }';

    var gen = new Jison.Generator(grammar, {type: "lalr"});
    var parser = gen.createParser();
    var gen2 = new Jison.Generator(grammar, {type: "slr"});
    var parser2 = gen2.createParser();
    assert.deepEqual(gen.table, gen2.table, "SLR(1) and LALR(1) tables should be equal");
    assert.ok(parser.parse(source));
};

exports["test LR(1) grammar"] = function () {
    var grammar = {
        "comment": "Produces a reduce-reduce conflict unless using LR(1).",
        "tokens": "z d b c a",
        "start": "S",
        "bnf": {
            "S" :[ "a A c",
                   "a B d",
                   "b A d",
                   "b B c"],
            "A" :[ "z" ],
            "B" :[ "z" ]
        }
    };

    var gen = new Jison.Generator(grammar, {type: "lalr"});
    assert.equal(gen.conflicts, 2);
};
