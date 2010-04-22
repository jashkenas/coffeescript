/* Jison generated parser */
var bnf = (function(){
var parser = {trace: function trace() {
},
yy: {},
symbols_: {"error":2,"spec":3,"declaration_list":4,"%%":5,"grammar":6,"EOF":7,"declaration":8,"START":9,"id":10,"LEX_BLOCK":11,"operator":12,"associativity":13,"token_list":14,"LEFT":15,"RIGHT":16,"NONASSOC":17,"symbol":18,"production_list":19,"production":20,":":21,"handle_list":22,";":23,"|":24,"handle_action":25,"handle":26,"prec":27,"action":28,"PREC":29,"STRING":30,"ID":31,"ACTION":32,"$accept":0,"$end":1},
terminals_: {"2":"error","5":"%%","7":"EOF","9":"START","11":"LEX_BLOCK","15":"LEFT","16":"RIGHT","17":"NONASSOC","21":":","23":";","24":"|","29":"PREC","30":"STRING","31":"ID","32":"ACTION"},
productions_: [0,[3,4],[3,5],[4,2],[4,0],[8,2],[8,1],[8,1],[12,2],[13,1],[13,1],[13,1],[14,2],[14,1],[6,1],[19,2],[19,1],[20,4],[22,3],[22,1],[25,3],[26,2],[26,0],[27,2],[27,0],[18,1],[18,1],[10,1],[28,1],[28,0]],
performAction: function anonymous(yytext, yyleng, yylineno, yy) {
    var $$ = arguments[5], $0 = arguments[5].length;
    switch (arguments[4]) {
      case 1:
        this.$ = $$[$0 - 4 + 1 - 1];
        this.$.bnf = $$[$0 - 4 + 3 - 1];
        return this.$;
        break;
      case 2:
        this.$ = $$[$0 - 5 + 1 - 1];
        this.$.bnf = $$[$0 - 5 + 3 - 1];
        return this.$;
        break;
      case 3:
        this.$ = $$[$0 - 2 + 1 - 1];
        yy.addDeclaration(this.$, $$[$0 - 2 + 2 - 1]);
        break;
      case 4:
        this.$ = {};
        break;
      case 5:
        this.$ = {start: $$[$0 - 2 + 2 - 1]};
        break;
      case 6:
        this.$ = {lex: $$[$0 - 1 + 1 - 1]};
        break;
      case 7:
        this.$ = {operator: $$[$0 - 1 + 1 - 1]};
        break;
      case 8:
        this.$ = [$$[$0 - 2 + 1 - 1]];
        this.$.push.apply(this.$, $$[$0 - 2 + 2 - 1]);
        break;
      case 9:
        this.$ = "left";
        break;
      case 10:
        this.$ = "right";
        break;
      case 11:
        this.$ = "nonassoc";
        break;
      case 12:
        this.$ = $$[$0 - 2 + 1 - 1];
        this.$.push($$[$0 - 2 + 2 - 1]);
        break;
      case 13:
        this.$ = [$$[$0 - 1 + 1 - 1]];
        break;
      case 14:
        this.$ = $$[$0 - 1 + 1 - 1];
        break;
      case 15:
        this.$ = $$[$0 - 2 + 1 - 1];
        this.$[$$[$0 - 2 + 2 - 1][0]] = $$[$0 - 2 + 2 - 1][1];
        break;
      case 16:
        this.$ = {};
        this.$[$$[$0 - 1 + 1 - 1][0]] = $$[$0 - 1 + 1 - 1][1];
        break;
      case 17:
        this.$ = [$$[$0 - 4 + 1 - 1], $$[$0 - 4 + 3 - 1]];
        break;
      case 18:
        this.$ = $$[$0 - 3 + 1 - 1];
        this.$.push($$[$0 - 3 + 3 - 1]);
        break;
      case 19:
        this.$ = [$$[$0 - 1 + 1 - 1]];
        break;
      case 20:
        this.$ = [$$[$0 - 3 + 1 - 1].length ? $$[$0 - 3 + 1 - 1].join(" ") : ""];
        if ($$[$0 - 3 + 3 - 1]) {
            this.$.push($$[$0 - 3 + 3 - 1]);
        }
        if ($$[$0 - 3 + 2 - 1]) {
            this.$.push($$[$0 - 3 + 2 - 1]);
        }
        if (this.$.length === 1) {
            this.$ = this.$[0];
        }
        break;
      case 21:
        this.$ = $$[$0 - 2 + 1 - 1];
        this.$.push($$[$0 - 2 + 2 - 1]);
        break;
      case 22:
        this.$ = [];
        break;
      case 23:
        this.$ = {prec: $$[$0 - 2 + 2 - 1]};
        break;
      case 24:
        this.$ = null;
        break;
      case 25:
        this.$ = $$[$0 - 1 + 1 - 1];
        break;
      case 26:
        this.$ = yytext;
        break;
      case 27:
        this.$ = yytext;
        break;
      case 28:
        this.$ = yytext;
        break;
      case 29:
        this.$ = "";
        break;
      default:;
    }
},
table: [{"3":1,"4":2,"5":[2,4],"9":[2,4],"11":[2,4],"15":[2,4],"16":[2,4],"17":[2,4]},{"1":[3]},{"5":[1,3],"8":4,"9":[1,5],"11":[1,6],"12":7,"13":8,"15":[1,9],"16":[1,10],"17":[1,11]},{"6":12,"19":13,"20":14,"10":15,"31":[1,16]},{"5":[2,3],"9":[2,3],"11":[2,3],"15":[2,3],"16":[2,3],"17":[2,3]},{"10":17,"31":[1,16]},{"17":[2,6],"16":[2,6],"15":[2,6],"11":[2,6],"9":[2,6],"5":[2,6]},{"17":[2,7],"16":[2,7],"15":[2,7],"11":[2,7],"9":[2,7],"5":[2,7]},{"14":18,"18":19,"10":20,"30":[1,21],"31":[1,16]},{"30":[2,9],"31":[2,9]},{"30":[2,10],"31":[2,10]},{"30":[2,11],"31":[2,11]},{"7":[1,22],"5":[1,23]},{"20":24,"10":15,"31":[1,16],"7":[2,14],"5":[2,14]},{"5":[2,16],"7":[2,16],"31":[2,16]},{"21":[1,25]},{"21":[2,27],"5":[2,27],"9":[2,27],"11":[2,27],"15":[2,27],"16":[2,27],"17":[2,27],"31":[2,27],"30":[2,27],"23":[2,27],"24":[2,27],"32":[2,27],"29":[2,27]},{"17":[2,5],"16":[2,5],"15":[2,5],"11":[2,5],"9":[2,5],"5":[2,5]},{"18":26,"10":20,"30":[1,21],"31":[1,16],"5":[2,8],"9":[2,8],"11":[2,8],"15":[2,8],"16":[2,8],"17":[2,8]},{"17":[2,13],"16":[2,13],"15":[2,13],"11":[2,13],"9":[2,13],"5":[2,13],"31":[2,13],"30":[2,13]},{"30":[2,25],"31":[2,25],"5":[2,25],"9":[2,25],"11":[2,25],"15":[2,25],"16":[2,25],"17":[2,25],"29":[2,25],"32":[2,25],"24":[2,25],"23":[2,25]},{"30":[2,26],"31":[2,26],"5":[2,26],"9":[2,26],"11":[2,26],"15":[2,26],"16":[2,26],"17":[2,26],"29":[2,26],"32":[2,26],"24":[2,26],"23":[2,26]},{"1":[2,1]},{"7":[1,27]},{"5":[2,15],"7":[2,15],"31":[2,15]},{"22":28,"25":29,"26":30,"23":[2,22],"24":[2,22],"32":[2,22],"29":[2,22],"31":[2,22],"30":[2,22]},{"17":[2,12],"16":[2,12],"15":[2,12],"11":[2,12],"9":[2,12],"5":[2,12],"31":[2,12],"30":[2,12]},{"1":[2,2]},{"23":[1,31],"24":[1,32]},{"23":[2,19],"24":[2,19]},{"27":33,"18":34,"29":[1,35],"10":20,"30":[1,21],"31":[1,16],"23":[2,24],"24":[2,24],"32":[2,24]},{"31":[2,17],"7":[2,17],"5":[2,17]},{"25":36,"26":30,"23":[2,22],"24":[2,22],"32":[2,22],"29":[2,22],"31":[2,22],"30":[2,22]},{"28":37,"32":[1,38],"23":[2,29],"24":[2,29]},{"23":[2,21],"24":[2,21],"32":[2,21],"29":[2,21],"31":[2,21],"30":[2,21]},{"18":39,"10":20,"30":[1,21],"31":[1,16]},{"23":[2,18],"24":[2,18]},{"24":[2,20],"23":[2,20]},{"23":[2,28],"24":[2,28]},{"23":[2,23],"24":[2,23],"32":[2,23]}],
parseError: function parseError(str, hash) {
    throw new Error(str);
},
parse: function parse(input) {
    var self = this, stack = [0], vstack = [null], table = this.table, yytext = "", yylineno = 0, yyleng = 0, shifts = 0, reductions = 0, recovering = 0, TERROR = 2, EOF = 1;
    this.lexer.setInput(input);
    this.lexer.yy = this.yy;
    this.yy.lexer = this.lexer;
    var parseError = this.yy.parseError = typeof this.yy.parseError == "function" ? this.yy.parseError : this.parseError;

    function popStack(n) {
        stack.length = stack.length - 2 * n;
        vstack.length = vstack.length - n;
    }


    function checkRecover(st) {
        for (var p in table[st]) {
            if (p == TERROR) {
                return true;
            }
        }
        return false;
    }


    function lex() {
        var token;
        token = self.lexer.lex() || 1;
        if (typeof token !== "number") {
            token = self.symbols_[token];
        }
        return token;
    }

    var symbol, preErrorSymbol, state, action, a, r, yyval = {}, p, len, newState, expected, recovered = false;
    symbol = lex();
    while (true) {
        state = stack[stack.length - 1];
        action = table[state] && table[state][symbol];
        if (typeof action === "undefined" || !action.length || !action[0]) {
            if (!recovering) {
                expected = [];
                for (p in table[state]) {
                    if (this.terminals_[p] && p > 2) {
                        expected.push("'" + this.terminals_[p] + "'");
                    }
                }
                if (this.lexer.showPosition) {
                    parseError.call(this, "Parse error on line " + (yylineno + 1) + ":\n" + this.lexer.showPosition() + "\nExpecting " + expected.join(", "), {text: this.lexer.match, token: this.terminals_[symbol] || symbol, line: this.lexer.yylineno, expected: expected});
                } else {
                    parseError.call(this, "Parse error on line " + (yylineno + 1) + ": Unexpected '" + this.terminals_[symbol] + "'", {text: this.lexer.match, token: this.terminals_[symbol] || symbol, line: this.lexer.yylineno, expected: expected});
                }
            }
            if (recovering == 3) {
                if (symbol == EOF) {
                    throw "Parsing halted.";
                }
                yyleng = this.lexer.yyleng;
                yytext = this.lexer.yytext;
                yylineno = this.lexer.yylineno;
                symbol = lex();
            }
            while (true) {
                if (checkRecover(state)) {
                    break;
                }
                if (state == 0) {
                    throw "Parsing halted.";
                }
                popStack(1);
                state = stack[stack.length - 1];
            }
            preErrorSymbol = symbol;
            symbol = TERROR;
            state = stack[stack.length - 1];
            action = table[state] && table[state][TERROR];
            recovering = 3;
        }
        if (action[0] instanceof Array && action.length > 1) {
            throw new Error("Parse Error: multiple actions possible at state: " + state + ", token: " + symbol);
        }
        a = action;
        switch (a[0]) {
          case 1:
            shifts++;
            stack.push(symbol);
            vstack.push(this.lexer.yytext);
            stack.push(a[1]);
            if (!preErrorSymbol) {
                yyleng = this.lexer.yyleng;
                yytext = this.lexer.yytext;
                yylineno = this.lexer.yylineno;
                symbol = lex();
                if (recovering > 0) {
                    recovering--;
                }
            } else {
                symbol = preErrorSymbol;
                preErrorSymbol = null;
            }
            break;
          case 2:
            reductions++;
            len = this.productions_[a[1]][1];
            yyval.$ = vstack[vstack.length - len];
            r = this.performAction.call(yyval, yytext, yyleng, yylineno, this.yy, a[1], vstack);
            if (typeof r !== "undefined") {
                return r;
            }
            if (len) {
                stack = stack.slice(0, -1 * len * 2);
                vstack = vstack.slice(0, -1 * len);
            }
            stack.push(this.productions_[a[1]][0]);
            vstack.push(yyval.$);
            newState = table[stack[stack.length - 2]][stack[stack.length - 1]];
            stack.push(newState);
            break;
          case 3:
            this.reductionCount = reductions;
            this.shiftCount = shifts;
            return true;
          default:;
        }
    }
    return true;
}};/* Jison generated lexer */
var lexer = (function(){var lexer = ({EOF:"",
parseError:function parseError(str, hash) {
    if (this.yy.parseError) {
        this.yy.parseError(str, hash);
    } else {
        throw new Error(str);
    }
},
setInput:function (input) {
    this._input = input;
    this._more = this._less = this.done = false;
    this.yylineno = this.yyleng = 0;
    this.yytext = this.matched = this.match = "";
    return this;
},
input:function () {
    var ch = this._input[0];
    this.yytext += ch;
    this.yyleng++;
    this.match += ch;
    this.matched += ch;
    var lines = ch.match(/\n/);
    if (lines) {
        this.yylineno++;
    }
    this._input = this._input.slice(1);
    return ch;
},
unput:function (ch) {
    this._input = ch + this._input;
    return this;
},
more:function () {
    this._more = true;
    return this;
},
pastInput:function () {
    var past = this.matched.substr(0, this.matched.length - this.match.length);
    return (past.length > 20 ? "..." : "") + past.substr(-20).replace(/\n/g, "");
},
upcomingInput:function () {
    var next = this.match;
    if (next.length < 20) {
        next += this._input.substr(0, 20 - next.length);
    }
    return (next.substr(0, 20) + (next.length > 20 ? "..." : "")).replace(/\n/g, "");
},
showPosition:function () {
    var pre = this.pastInput();
    var c = (new Array(pre.length + 1)).join("-");
    return pre + this.upcomingInput() + "\n" + c + "^";
},
next:function () {
    if (this.done) {
        return this.EOF;
    }
    if (!this._input) {
        this.done = true;
    }
    var token, match, lines;
    if (!this._more) {
        this.yytext = "";
        this.match = "";
    }
    for (var i = 0; i < this.rules.length; i++) {
        match = this._input.match(this.rules[i]);
        if (match) {
            lines = match[0].match(/\n/g);
            if (lines) {
                this.yylineno += lines.length;
            }
            this.yytext += match[0];
            this.match += match[0];
            this.matches = match;
            this.yyleng = this.yytext.length;
            this._more = false;
            this._input = this._input.slice(match[0].length);
            this.matched += match[0];
            token = this.performAction.call(this, this.yy, this, i);
            if (token) {
                return token;
            } else {
                return;
            }
        }
    }
    if (this._input == this.EOF) {
        return this.EOF;
    } else {
        this.parseError("Lexical error on line " + (this.yylineno + 1) + ". Unrecognized text.\n" + this.showPosition(), {text: "", token: null, line: this.yylineno});
    }
},
lex:function () {
    var r = this.next();
    if (typeof r !== "undefined") {
        return r;
    } else {
        return this.lex();
    }
}});
lexer.performAction = function anonymous(yy, yy_) {
    switch (arguments[2]) {
      case 0:
        break;
      case 1:
        break;
      case 2:
        return yy.lexComment(this);
        break;
      case 3:
        return 31;
        break;
      case 4:
        yy_.yytext = yy_.yytext.substr(1, yy_.yyleng - 2);
        return 30;
        break;
      case 5:
        yy_.yytext = yy_.yytext.substr(1, yy_.yyleng - 2);
        return 30;
        break;
      case 6:
        return 21;
        break;
      case 7:
        return 23;
        break;
      case 8:
        return 24;
        break;
      case 9:
        return 5;
        break;
      case 10:
        return 29;
        break;
      case 11:
        return 9;
        break;
      case 12:
        return 15;
        break;
      case 13:
        return 16;
        break;
      case 14:
        return 17;
        break;
      case 15:
        return 11;
        break;
      case 16:
        break;
      case 17:
        break;
      case 18:
        return yy.lexAction(this);
        break;
      case 19:
        yy_.yytext = yy_.yytext.substr(1, yy_.yyleng - 2);
        return 32;
        break;
      case 20:
        yy_.yytext = yy_.yytext.substr(2, yy_.yytext.length - 4);
        return 32;
        break;
      case 21:
        break;
      case 22:
        return 7;
        break;
      default:;
    }
};
lexer.rules = [/^\s+/,/^\/\/.*/,/^\/\*[^*]*\*/,/^[a-zA-Z][a-zA-Z0-9_-]*/,/^"[^"]+"/,/^'[^']+'/,/^:/,/^;/,/^\|/,/^%%/,/^%prec\b/,/^%start\b/,/^%left\b/,/^%right\b/,/^%nonassoc\b/,/^%lex[\w\W]*?\/lex\b/,/^%[a-zA-Z]+[^\n]*/,/^<[a-zA-Z]*>/,/^\{\{[^}]*\}/,/^\{[^}]*\}/,/^%\{(.|\n)*?%\}/,/^./,/^$/];return lexer;})()
parser.lexer = lexer;
return parser;
})();
if (typeof require !== 'undefined') {
exports.parser = bnf;
exports.parse = function () { return bnf.parse.apply(bnf, arguments); }
exports.main = function commonjsMain(args) {
    var cwd = require("file").path(require("file").cwd());
    if (!args[1]) {
        throw new Error("Usage: " + args[0] + " FILE");
    }
    var source = cwd.join(args[1]).read({charset: "utf-8"});
    exports.parser.parse(source);
}
if (require.main === module) {
	exports.main(require("system").args);
}
}
