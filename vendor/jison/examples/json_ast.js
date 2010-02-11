var Generator = require("jison").Generator;
var system = require("system");
var fs = require("file");

exports.grammar = {
    "comment": "ECMA-262 5th Edition, 15.12.1 The JSON Grammar. Parses JSON strings into objects.",
    "author": "Zach Carter",

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
    "start": "JSONText",

    "bnf": {
        "JSONString": [[ "STRING", "$$ = yytext;" ]],

        "JSONNumber": [[ "NUMBER", "$$ = Number(yytext);" ]],

        "JSONNullLiteral": [[ "NULL", "$$ = null;" ]],

        "JSONBooleanLiteral": [[ "TRUE", "$$ = true;" ],
                               [ "FALSE", "$$ = false;" ]],


        "JSONText": [[ "JSONValue", "return $$ = $1;" ]],

        "JSONValue": [[ "JSONNullLiteral",    "$$ = $1;" ],
                      [ "JSONBooleanLiteral", "$$ = $1;" ],
                      [ "JSONString",         "$$ = $1;" ],
                      [ "JSONNumber",         "$$ = $1;" ],
                      [ "JSONObject",         "$$ = $1;" ],
                      [ "JSONArray",          "$$ = $1;" ]],

        "JSONObject": [[ "{ }", "$$ = {};" ],
                       [ "{ JSONMemberList }", "$$ = $2;" ]],

        "JSONMember": [[ "JSONString : JSONValue", "$$ = [$1, $3];" ]],

        "JSONMemberList": [[ "JSONMember", "$$ = {}; $$[$1[0]] = $1[1];" ],
                           [ "JSONMemberList , JSONMember", "$$ = $1; $1[$3[0]] = $3[1];" ]],

        "JSONArray": [[ "[ ]", "$$ = [];" ],
                      [ "[ JSONElementList ]", "$$ = $2;" ]],

        "JSONElementList": [[ "JSONValue", "$$ = [$1];" ],
                            [ "JSONElementList , JSONValue", "$$ = $1; $1.push($3);" ]]
    }
};

var options = {type: "slr", moduleType: "commonjs", moduleName: "jsonparse"};

exports.main = function main (args) {
    var cwd = fs.path(fs.cwd()),
        code = new Generator(exports.grammar, options).generate(),
        stream = cwd.join(options.moduleName+".js").open("w");
    stream.print(code).close();
};

if (require.main === module)
    exports.main(system.args);

