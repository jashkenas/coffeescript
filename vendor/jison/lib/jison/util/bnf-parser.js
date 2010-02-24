/* Jison generated parser */
var bnf = (function(){
var parser = {trace: function trace() {
},
yy: {},
symbols_: {"spec":2,"declaration_list":3,"%%":4,"grammar":5,"EOF":6,"declaration":7,"START":8,"id":9,"operator":10,"associativity":11,"token_list":12,"LEFT":13,"RIGHT":14,"NONASSOC":15,"symbol":16,"production_list":17,"production":18,":":19,"handle_list":20,";":21,"|":22,"handle_action":23,"handle":24,"action":25,"prec":26,"PREC":27,"STRING":28,"ID":29,"ACTION":30,"$accept":0,"$end":1},
terminals_: {"4":"%%","6":"EOF","8":"START","13":"LEFT","14":"RIGHT","15":"NONASSOC","19":":","21":";","22":"|","27":"PREC","28":"STRING","29":"ID","30":"ACTION"},
productions_: [0,[2,4],[2,5],[3,2],[3,0],[7,2],[7,1],[10,2],[11,1],[11,1],[11,1],[12,2],[12,1],[5,1],[17,2],[17,1],[18,4],[20,3],[20,1],[23,3],[24,2],[24,0],[26,2],[26,0],[16,1],[16,1],[9,1],[25,1],[25,0]],
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
        this.$ = {operator: $$[$0 - 1 + 1 - 1]};
        break;
      case 7:
        this.$ = [$$[$0 - 2 + 1 - 1]];
        this.$.push.apply(this.$, $$[$0 - 2 + 2 - 1]);
        break;
      case 8:
        this.$ = "left";
        break;
      case 9:
        this.$ = "right";
        break;
      case 10:
        this.$ = "nonassoc";
        break;
      case 11:
        this.$ = $$[$0 - 2 + 1 - 1];
        this.$.push($$[$0 - 2 + 2 - 1]);
        break;
      case 12:
        this.$ = [$$[$0 - 1 + 1 - 1]];
        break;
      case 13:
        this.$ = $$[$0 - 1 + 1 - 1];
        break;
      case 14:
        this.$ = $$[$0 - 2 + 1 - 1];
        this.$[$$[$0 - 2 + 2 - 1][0]] = $$[$0 - 2 + 2 - 1][1];
        break;
      case 15:
        this.$ = {};
        this.$[$$[$0 - 1 + 1 - 1][0]] = $$[$0 - 1 + 1 - 1][1];
        break;
      case 16:
        this.$ = [$$[$0 - 4 + 1 - 1], $$[$0 - 4 + 3 - 1]];
        break;
      case 17:
        this.$ = $$[$0 - 3 + 1 - 1];
        this.$.push($$[$0 - 3 + 3 - 1]);
        break;
      case 18:
        this.$ = [$$[$0 - 1 + 1 - 1]];
        break;
      case 19:
        this.$ = [$$[$0 - 3 + 1 - 1].length ? $$[$0 - 3 + 1 - 1].join(" ") : ""];
        if ($$[$0 - 3 + 2 - 1]) {
            this.$.push($$[$0 - 3 + 2 - 1]);
        }
        if ($$[$0 - 3 + 3 - 1]) {
            this.$.push($$[$0 - 3 + 3 - 1]);
        }
        if (this.$.length === 1) {
            this.$ = this.$[0];
        }
        break;
      case 20:
        this.$ = $$[$0 - 2 + 1 - 1];
        this.$.push($$[$0 - 2 + 2 - 1]);
        break;
      case 21:
        this.$ = [];
        break;
      case 22:
        this.$ = {prec: $$[$0 - 2 + 2 - 1]};
        break;
      case 23:
        this.$ = null;
        break;
      case 24:
        this.$ = $$[$0 - 1 + 1 - 1];
        break;
      case 25:
        this.$ = yytext;
        break;
      case 26:
        this.$ = yytext;
        break;
      case 27:
        this.$ = yytext;
        break;
      case 28:
        this.$ = "";
        break;
      default:;
    }
},
table: [{"2":1,"3":2,"4":[[2,4]],"15":[[2,4]],"14":[[2,4]],"13":[[2,4]],"8":[[2,4]]},{"1":[[3]]},{"4":[[1,3]],"7":4,"8":[[1,5]],"10":6,"11":7,"13":[[1,8]],"14":[[1,9]],"15":[[1,10]]},{"5":11,"17":12,"18":13,"9":14,"29":[[1,15]]},{"4":[[2,3]],"15":[[2,3]],"14":[[2,3]],"13":[[2,3]],"8":[[2,3]]},{"9":16,"29":[[1,15]]},{"8":[[2,6]],"13":[[2,6]],"14":[[2,6]],"15":[[2,6]],"4":[[2,6]]},{"12":17,"16":18,"9":19,"28":[[1,20]],"29":[[1,15]]},{"29":[[2,8]],"28":[[2,8]]},{"29":[[2,9]],"28":[[2,9]]},{"29":[[2,10]],"28":[[2,10]]},{"6":[[1,21]],"4":[[1,22]]},{"18":23,"9":14,"29":[[1,15]],"6":[[2,13]],"4":[[2,13]]},{"4":[[2,15]],"6":[[2,15]],"29":[[2,15]]},{"19":[[1,24]]},{"19":[[2,26]],"4":[[2,26]],"15":[[2,26]],"14":[[2,26]],"13":[[2,26]],"8":[[2,26]],"28":[[2,26]],"29":[[2,26]],"21":[[2,26]],"22":[[2,26]],"27":[[2,26]],"30":[[2,26]]},{"8":[[2,5]],"13":[[2,5]],"14":[[2,5]],"15":[[2,5]],"4":[[2,5]]},{"16":25,"9":19,"28":[[1,20]],"29":[[1,15]],"4":[[2,7]],"15":[[2,7]],"14":[[2,7]],"13":[[2,7]],"8":[[2,7]]},{"8":[[2,12]],"13":[[2,12]],"14":[[2,12]],"15":[[2,12]],"4":[[2,12]],"28":[[2,12]],"29":[[2,12]]},{"29":[[2,24]],"28":[[2,24]],"4":[[2,24]],"15":[[2,24]],"14":[[2,24]],"13":[[2,24]],"8":[[2,24]],"30":[[2,24]],"27":[[2,24]],"22":[[2,24]],"21":[[2,24]]},{"29":[[2,25]],"28":[[2,25]],"4":[[2,25]],"15":[[2,25]],"14":[[2,25]],"13":[[2,25]],"8":[[2,25]],"30":[[2,25]],"27":[[2,25]],"22":[[2,25]],"21":[[2,25]]},{"1":[[2,1]]},{"6":[[1,26]]},{"4":[[2,14]],"6":[[2,14]],"29":[[2,14]]},{"20":27,"23":28,"24":29,"21":[[2,21]],"22":[[2,21]],"27":[[2,21]],"30":[[2,21]],"28":[[2,21]],"29":[[2,21]]},{"8":[[2,11]],"13":[[2,11]],"14":[[2,11]],"15":[[2,11]],"4":[[2,11]],"28":[[2,11]],"29":[[2,11]]},{"1":[[2,2]]},{"21":[[1,30]],"22":[[1,31]]},{"21":[[2,18]],"22":[[2,18]]},{"25":32,"16":33,"30":[[1,34]],"9":19,"28":[[1,20]],"29":[[1,15]],"21":[[2,28]],"22":[[2,28]],"27":[[2,28]]},{"29":[[2,16]],"6":[[2,16]],"4":[[2,16]]},{"23":35,"24":29,"21":[[2,21]],"22":[[2,21]],"27":[[2,21]],"30":[[2,21]],"28":[[2,21]],"29":[[2,21]]},{"26":36,"27":[[1,37]],"21":[[2,23]],"22":[[2,23]]},{"21":[[2,20]],"22":[[2,20]],"27":[[2,20]],"30":[[2,20]],"28":[[2,20]],"29":[[2,20]]},{"21":[[2,27]],"22":[[2,27]],"27":[[2,27]]},{"21":[[2,17]],"22":[[2,17]]},{"22":[[2,19]],"21":[[2,19]]},{"16":38,"9":19,"28":[[1,20]],"29":[[1,15]]},{"21":[[2,22]],"22":[[2,22]]}],
parseError: function parseError(str, hash) {
    throw new Error(str);
},
parse: function parse(input) {
    var self = this, stack = [0], vstack = [null], table = this.table, yytext = "", yylineno = 0, yyleng = 0, shifts = 0, reductions = 0;
    this.lexer.setInput(input);
    this.lexer.yy = this.yy;
    var parseError = this.yy.parseError = this.yy.parseError || this.parseError;

    function lex() {
        var token;
        token = self.lexer.lex() || 1;
        if (typeof token !== "number") {
            token = self.symbols_[token];
        }
        return token;
    }

    var symbol, state, action, a, r, yyval = {}, p, len, ip = 0, newState, expected;
    symbol = lex();
    while (true) {
        state = stack[stack.length - 1];
        action = table[state] && table[state][symbol];
        if (typeof action == "undefined" || !action.length || !action[0]) {
            expected = [];
            for (p in table[state]) {
                if (this.terminals_[p] && p != 1) {
                    expected.push("'" + this.terminals_[p] + "'");
                }
            }
            if (this.lexer.showPosition) {
                parseError("Parse error on line " + (yylineno + 1) + ":\n" + this.lexer.showPosition() + "\nExpecting " + expected.join(", "), {text: this.lexer.match, token: this.terminals_[symbol], line: this.lexer.yylineno, expected: expected});
            } else {
                parseError("Parse error on line " + (yylineno + 1) + ": Unexpected '" + this.terminals_[symbol] + "'", {text: this.lexer.match, token: this.terminals_[symbol], line: this.lexer.yylineno, expected: expected});
            }
        }
        this.trace("action:", action);
        if (action.length > 1) {
            throw new Error("Parse Error: multiple actions possible at state: " + state + ", token: " + symbol);
        }
        a = action[0];
        switch (a[0]) {
          case 1:
            shifts++;
            stack.push(symbol);
            ++ip;
            yyleng = this.lexer.yyleng;
            yytext = this.lexer.yytext;
            yylineno = this.lexer.yylineno;
            symbol = lex();
            vstack.push(null);
            stack.push(a[1]);
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
        return yy.lexComment(this);
        break;
      case 2:
        return 29;
        break;
      case 3:
        yy_.yytext = yy_.yytext.substr(1, yy_.yyleng - 2);
        return 28;
        break;
      case 4:
        yy_.yytext = yy_.yytext.substr(1, yy_.yyleng - 2);
        return 28;
        break;
      case 5:
        return 19;
        break;
      case 6:
        return 21;
        break;
      case 7:
        return 22;
        break;
      case 8:
        return 4;
        break;
      case 9:
        return 27;
        break;
      case 10:
        return 8;
        break;
      case 11:
        return 13;
        break;
      case 12:
        return 14;
        break;
      case 13:
        return 15;
        break;
      case 14:
        break;
      case 15:
        return yy.lexAction(this);
        break;
      case 16:
        yy_.yytext = yy_.yytext.substr(1, yy_.yyleng - 2);
        return 30;
        break;
      case 17:
        yy_.yytext = yy_.yytext.substr(1, yy_.yyleng - 2);
        return 30;
        break;
      case 18:
        break;
      case 19:
        return 6;
        break;
      default:;
    }
};
lexer.rules = [/^\s+/, /^\/\*[^*]*\*/, /^[a-zA-Z][a-zA-Z0-9_-]*/, /^"[^"]+"/, /^'[^']+'/, /^:/, /^;/, /^\|/, /^%%/, /^%prec\b/, /^%start\b/, /^%left\b/, /^%right\b/, /^%nonassoc\b/, /^%[a-zA-Z]+[^\n]*/, /^\{\{[^}]*\}/, /^\{[^}]*\}/, /^<[^>]*>/, /^./, /^$/];return lexer;})()
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
    this.parse(source);
}
if (require.main === module) {
	exports.main(require("system").args);
}
}
