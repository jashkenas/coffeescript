if (typeof require !== 'undefined') {
    var bnf = require("./util/bnf-parser").parser;
    var jisonlex = require("./jisonlex");
    exports.parse = function parse () { return bnf.parse.apply(bnf, arguments) };
}

// adds a declaration to the grammar
bnf.yy.addDeclaration = function (grammar, decl) {
    if (decl.start) {
        grammar.start = decl.start;
    }
    else if (decl.lex) {
        grammar.lex = parseLex(decl.lex);
    }
    else if (decl.operator) {
        if (!grammar.operators) {
            grammar.operators = [];
        }
        grammar.operators.push(decl.operator);
    }

};

// helps tokenize comments
bnf.yy.lexComment = function (lexer) {
    var ch = lexer.input();
    if (ch === '/') {
        lexer.yytext = lexer.yytext.replace(/\*(.|\s)\/\*/, '*$1');
        return;
    } else {
        lexer.unput('/*');
        lexer.more();
    }
}

// helps tokenize actions
bnf.yy.lexAction = function (lexer) {
    var ch = lexer.input();
    if (ch === '}') {
        lexer.yytext = lexer.yytext.substr(2, lexer.yyleng-4).replace(/\}(.|\s)\{\{/, '}$1');
        return 'ACTION';
    } else {
        lexer.unput('{{');
        lexer.more();
    }
}

// parse an embedded lex section
var parseLex = function (text) {
    return jisonlex.parse(text.replace(/(?:^%lex)|(?:\/lex$)/g, ''));
}

