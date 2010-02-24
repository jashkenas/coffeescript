/* Jison generated parser */
var jisonlex = (function(){
var parser = {trace: function trace() {
},
yy: {},
symbols_: {"lex":2,"definitions":3,"include":4,"%%":5,"rules":6,"EOF":7,"action":8,"definition":9,"name":10,"regex":11,"NAME":12,"rule":13,"ACTION":14,"regex_list":15,"|":16,"regex_concat":17,"regex_base":18,"(":19,")":20,"+":21,"*":22,"?":23,"/":24,"name_expansion":25,"range_regex":26,"any_group_regex":27,".":28,"^":29,"$":30,"string":31,"escape_char":32,"{":33,"}":34,"ANY_GROUP_REGEX":35,"ESCAPE_CHAR":36,"RANGE_REGEX":37,"STRING_LIT":38,"$accept":0,"$end":1},
terminals_: {"5":"%%","7":"EOF","12":"NAME","14":"ACTION","16":"|","19":"(","20":")","21":"+","22":"*","23":"?","24":"/","28":".","29":"^","30":"$","33":"{","34":"}","35":"ANY_GROUP_REGEX","36":"ESCAPE_CHAR","37":"RANGE_REGEX","38":"STRING_LIT"},
productions_: [0,[2,6],[2,5],[4,1],[4,0],[3,2],[3,0],[9,2],[10,1],[6,2],[6,1],[13,2],[8,1],[11,1],[15,3],[15,1],[17,2],[17,1],[18,3],[18,2],[18,2],[18,2],[18,2],[18,1],[18,2],[18,1],[18,1],[18,1],[18,1],[18,1],[18,1],[25,3],[27,1],[32,1],[26,1],[31,1]],
performAction: function anonymous(yytext, yyleng, yylineno, yy) {
    var $$ = arguments[5], $0 = arguments[5].length;
    switch (arguments[4]) {
      case 1:
        this.$ = {rules: $$[$0 - 6 + 4 - 1]};
        if ($$[$0 - 6 + 1 - 1].length) {
            this.$.macros = $$[$0 - 6 + 1 - 1];
        }
        if ($$[$0 - 6 + 2 - 1]) {
            this.$.actionInclude = $$[$0 - 6 + 2 - 1];
        }
        return this.$;
        break;
      case 2:
        this.$ = {rules: $$[$0 - 5 + 4 - 1]};
        if ($$[$0 - 5 + 1 - 1].length) {
            this.$.macros = $$[$0 - 5 + 1 - 1];
        }
        if ($$[$0 - 5 + 2 - 1]) {
            this.$.actionInclude = $$[$0 - 5 + 2 - 1];
        }
        return this.$;
        break;
      case 5:
        this.$ = $$[$0 - 2 + 1 - 1];
        this.$.push($$[$0 - 2 + 2 - 1]);
        break;
      case 6:
        this.$ = [];
        break;
      case 7:
        this.$ = [$$[$0 - 2 + 1 - 1], $$[$0 - 2 + 2 - 1]];
        break;
      case 8:
        this.$ = yytext;
        break;
      case 9:
        this.$ = $$[$0 - 2 + 1 - 1];
        this.$.push($$[$0 - 2 + 2 - 1]);
        break;
      case 10:
        this.$ = [$$[$0 - 1 + 1 - 1]];
        break;
      case 11:
        this.$ = [$$[$0 - 2 + 1 - 1], $$[$0 - 2 + 2 - 1]];
        break;
      case 12:
        this.$ = yytext;
        break;
      case 13:
        this.$ = $$[$0 - 1 + 1 - 1];
        if (this.$.match(/[\w\d]$/)) {
            this.$ += "\\b";
        }
        break;
      case 14:
        this.$ = $$[$0 - 3 + 1 - 1] + "|" + $$[$0 - 3 + 3 - 1];
        break;
      case 16:
        this.$ = $$[$0 - 2 + 1 - 1] + $$[$0 - 2 + 2 - 1];
        break;
      case 18:
        this.$ = "(" + $$[$0 - 3 + 2 - 1] + ")";
        break;
      case 19:
        this.$ = $$[$0 - 2 + 1 - 1] + "+";
        break;
      case 20:
        this.$ = $$[$0 - 2 + 1 - 1] + "*";
        break;
      case 21:
        this.$ = $$[$0 - 2 + 1 - 1] + "?";
        break;
      case 22:
        this.$ = "(?=" + $$[$0 - 2 + 2 - 1] + ")";
        break;
      case 24:
        this.$ = $$[$0 - 2 + 1 - 1] + $$[$0 - 2 + 2 - 1];
        break;
      case 26:
        this.$ = ".";
        break;
      case 27:
        this.$ = "^";
        break;
      case 28:
        this.$ = "$";
        break;
      case 31:
        this.$ = "{" + $$[$0 - 3 + 2 - 1] + "}";
        break;
      case 32:
        this.$ = yytext;
        break;
      case 33:
        this.$ = yytext;
        break;
      case 34:
        this.$ = yytext;
        break;
      case 35:
        this.$ = yy.prepareString(yytext.substr(1, yytext.length - 2));
        break;
      default:;
    }
},
table: [{"2":1,"3":2,"5":[[2,6]],"14":[[2,6]],"12":[[2,6]]},{"1":[[3]]},{"4":3,"9":4,"8":5,"10":6,"14":[[1,7]],"12":[[1,8]],"5":[[2,4]]},{"5":[[1,9]]},{"5":[[2,5]],"14":[[2,5]],"12":[[2,5]]},{"5":[[2,3]]},{"11":10,"15":11,"17":12,"18":13,"19":[[1,14]],"24":[[1,15]],"25":16,"27":17,"28":[[1,18]],"29":[[1,19]],"30":[[1,20]],"31":21,"32":22,"33":[[1,23]],"35":[[1,24]],"38":[[1,25]],"36":[[1,26]]},{"5":[[2,12]],"7":[[2,12]],"36":[[2,12]],"38":[[2,12]],"35":[[2,12]],"33":[[2,12]],"19":[[2,12]],"24":[[2,12]],"28":[[2,12]],"29":[[2,12]],"30":[[2,12]]},{"30":[[2,8]],"29":[[2,8]],"28":[[2,8]],"24":[[2,8]],"19":[[2,8]],"33":[[2,8]],"35":[[2,8]],"38":[[2,8]],"36":[[2,8]],"34":[[2,8]]},{"6":27,"13":28,"11":29,"15":11,"17":12,"18":13,"19":[[1,14]],"24":[[1,15]],"25":16,"27":17,"28":[[1,18]],"29":[[1,19]],"30":[[1,20]],"31":21,"32":22,"33":[[1,23]],"35":[[1,24]],"38":[[1,25]],"36":[[1,26]]},{"12":[[2,7]],"14":[[2,7]],"5":[[2,7]]},{"16":[[1,30]],"5":[[2,13]],"14":[[2,13]],"12":[[2,13]]},{"18":31,"19":[[1,14]],"24":[[1,15]],"25":16,"27":17,"28":[[1,18]],"29":[[1,19]],"30":[[1,20]],"31":21,"32":22,"33":[[1,23]],"35":[[1,24]],"38":[[1,25]],"36":[[1,26]],"12":[[2,15]],"14":[[2,15]],"5":[[2,15]],"16":[[2,15]],"20":[[2,15]]},{"21":[[1,32]],"22":[[1,33]],"23":[[1,34]],"26":35,"37":[[1,36]],"16":[[2,17]],"5":[[2,17]],"14":[[2,17]],"12":[[2,17]],"36":[[2,17]],"38":[[2,17]],"35":[[2,17]],"33":[[2,17]],"24":[[2,17]],"28":[[2,17]],"29":[[2,17]],"30":[[2,17]],"19":[[2,17]],"20":[[2,17]]},{"15":37,"17":12,"18":13,"19":[[1,14]],"24":[[1,15]],"25":16,"27":17,"28":[[1,18]],"29":[[1,19]],"30":[[1,20]],"31":21,"32":22,"33":[[1,23]],"35":[[1,24]],"38":[[1,25]],"36":[[1,26]]},{"18":38,"19":[[1,14]],"24":[[1,15]],"25":16,"27":17,"28":[[1,18]],"29":[[1,19]],"30":[[1,20]],"31":21,"32":22,"33":[[1,23]],"35":[[1,24]],"38":[[1,25]],"36":[[1,26]]},{"19":[[2,23]],"30":[[2,23]],"29":[[2,23]],"28":[[2,23]],"24":[[2,23]],"33":[[2,23]],"35":[[2,23]],"38":[[2,23]],"36":[[2,23]],"12":[[2,23]],"14":[[2,23]],"5":[[2,23]],"16":[[2,23]],"21":[[2,23]],"22":[[2,23]],"23":[[2,23]],"37":[[2,23]],"20":[[2,23]]},{"19":[[2,25]],"30":[[2,25]],"29":[[2,25]],"28":[[2,25]],"24":[[2,25]],"33":[[2,25]],"35":[[2,25]],"38":[[2,25]],"36":[[2,25]],"12":[[2,25]],"14":[[2,25]],"5":[[2,25]],"16":[[2,25]],"21":[[2,25]],"22":[[2,25]],"23":[[2,25]],"37":[[2,25]],"20":[[2,25]]},{"19":[[2,26]],"30":[[2,26]],"29":[[2,26]],"28":[[2,26]],"24":[[2,26]],"33":[[2,26]],"35":[[2,26]],"38":[[2,26]],"36":[[2,26]],"12":[[2,26]],"14":[[2,26]],"5":[[2,26]],"16":[[2,26]],"21":[[2,26]],"22":[[2,26]],"23":[[2,26]],"37":[[2,26]],"20":[[2,26]]},{"19":[[2,27]],"30":[[2,27]],"29":[[2,27]],"28":[[2,27]],"24":[[2,27]],"33":[[2,27]],"35":[[2,27]],"38":[[2,27]],"36":[[2,27]],"12":[[2,27]],"14":[[2,27]],"5":[[2,27]],"16":[[2,27]],"21":[[2,27]],"22":[[2,27]],"23":[[2,27]],"37":[[2,27]],"20":[[2,27]]},{"19":[[2,28]],"30":[[2,28]],"29":[[2,28]],"28":[[2,28]],"24":[[2,28]],"33":[[2,28]],"35":[[2,28]],"38":[[2,28]],"36":[[2,28]],"12":[[2,28]],"14":[[2,28]],"5":[[2,28]],"16":[[2,28]],"21":[[2,28]],"22":[[2,28]],"23":[[2,28]],"37":[[2,28]],"20":[[2,28]]},{"19":[[2,29]],"30":[[2,29]],"29":[[2,29]],"28":[[2,29]],"24":[[2,29]],"33":[[2,29]],"35":[[2,29]],"38":[[2,29]],"36":[[2,29]],"12":[[2,29]],"14":[[2,29]],"5":[[2,29]],"16":[[2,29]],"21":[[2,29]],"22":[[2,29]],"23":[[2,29]],"37":[[2,29]],"20":[[2,29]]},{"19":[[2,30]],"30":[[2,30]],"29":[[2,30]],"28":[[2,30]],"24":[[2,30]],"33":[[2,30]],"35":[[2,30]],"38":[[2,30]],"36":[[2,30]],"12":[[2,30]],"14":[[2,30]],"5":[[2,30]],"16":[[2,30]],"21":[[2,30]],"22":[[2,30]],"23":[[2,30]],"37":[[2,30]],"20":[[2,30]]},{"10":39,"12":[[1,8]]},{"37":[[2,32]],"23":[[2,32]],"22":[[2,32]],"21":[[2,32]],"16":[[2,32]],"5":[[2,32]],"14":[[2,32]],"12":[[2,32]],"36":[[2,32]],"38":[[2,32]],"35":[[2,32]],"33":[[2,32]],"24":[[2,32]],"28":[[2,32]],"29":[[2,32]],"30":[[2,32]],"19":[[2,32]],"20":[[2,32]]},{"37":[[2,35]],"23":[[2,35]],"22":[[2,35]],"21":[[2,35]],"16":[[2,35]],"5":[[2,35]],"14":[[2,35]],"12":[[2,35]],"36":[[2,35]],"38":[[2,35]],"35":[[2,35]],"33":[[2,35]],"24":[[2,35]],"28":[[2,35]],"29":[[2,35]],"30":[[2,35]],"19":[[2,35]],"20":[[2,35]]},{"37":[[2,33]],"23":[[2,33]],"22":[[2,33]],"21":[[2,33]],"16":[[2,33]],"5":[[2,33]],"14":[[2,33]],"12":[[2,33]],"36":[[2,33]],"38":[[2,33]],"35":[[2,33]],"33":[[2,33]],"24":[[2,33]],"28":[[2,33]],"29":[[2,33]],"30":[[2,33]],"19":[[2,33]],"20":[[2,33]]},{"5":[[1,40]],"7":[[1,41]],"13":42,"11":29,"15":11,"17":12,"18":13,"19":[[1,14]],"24":[[1,15]],"25":16,"27":17,"28":[[1,18]],"29":[[1,19]],"30":[[1,20]],"31":21,"32":22,"33":[[1,23]],"35":[[1,24]],"38":[[1,25]],"36":[[1,26]]},{"5":[[2,10]],"7":[[2,10]],"36":[[2,10]],"38":[[2,10]],"35":[[2,10]],"33":[[2,10]],"19":[[2,10]],"24":[[2,10]],"28":[[2,10]],"29":[[2,10]],"30":[[2,10]]},{"8":43,"14":[[1,7]]},{"15":44,"17":12,"18":13,"19":[[1,14]],"24":[[1,15]],"25":16,"27":17,"28":[[1,18]],"29":[[1,19]],"30":[[1,20]],"31":21,"32":22,"33":[[1,23]],"35":[[1,24]],"38":[[1,25]],"36":[[1,26]]},{"21":[[1,32]],"22":[[1,33]],"23":[[1,34]],"26":35,"37":[[1,36]],"16":[[2,16]],"5":[[2,16]],"14":[[2,16]],"12":[[2,16]],"36":[[2,16]],"38":[[2,16]],"35":[[2,16]],"33":[[2,16]],"24":[[2,16]],"28":[[2,16]],"29":[[2,16]],"30":[[2,16]],"19":[[2,16]],"20":[[2,16]]},{"19":[[2,19]],"30":[[2,19]],"29":[[2,19]],"28":[[2,19]],"24":[[2,19]],"33":[[2,19]],"35":[[2,19]],"38":[[2,19]],"36":[[2,19]],"12":[[2,19]],"14":[[2,19]],"5":[[2,19]],"16":[[2,19]],"21":[[2,19]],"22":[[2,19]],"23":[[2,19]],"37":[[2,19]],"20":[[2,19]]},{"19":[[2,20]],"30":[[2,20]],"29":[[2,20]],"28":[[2,20]],"24":[[2,20]],"33":[[2,20]],"35":[[2,20]],"38":[[2,20]],"36":[[2,20]],"12":[[2,20]],"14":[[2,20]],"5":[[2,20]],"16":[[2,20]],"21":[[2,20]],"22":[[2,20]],"23":[[2,20]],"37":[[2,20]],"20":[[2,20]]},{"19":[[2,21]],"30":[[2,21]],"29":[[2,21]],"28":[[2,21]],"24":[[2,21]],"33":[[2,21]],"35":[[2,21]],"38":[[2,21]],"36":[[2,21]],"12":[[2,21]],"14":[[2,21]],"5":[[2,21]],"16":[[2,21]],"21":[[2,21]],"22":[[2,21]],"23":[[2,21]],"37":[[2,21]],"20":[[2,21]]},{"19":[[2,24]],"30":[[2,24]],"29":[[2,24]],"28":[[2,24]],"24":[[2,24]],"33":[[2,24]],"35":[[2,24]],"38":[[2,24]],"36":[[2,24]],"12":[[2,24]],"14":[[2,24]],"5":[[2,24]],"16":[[2,24]],"21":[[2,24]],"22":[[2,24]],"23":[[2,24]],"37":[[2,24]],"20":[[2,24]]},{"37":[[2,34]],"23":[[2,34]],"22":[[2,34]],"21":[[2,34]],"16":[[2,34]],"5":[[2,34]],"14":[[2,34]],"12":[[2,34]],"36":[[2,34]],"38":[[2,34]],"35":[[2,34]],"33":[[2,34]],"24":[[2,34]],"28":[[2,34]],"29":[[2,34]],"30":[[2,34]],"19":[[2,34]],"20":[[2,34]]},{"20":[[1,45]],"16":[[1,30]]},{"21":[[1,32]],"22":[[1,33]],"23":[[1,34]],"26":35,"37":[[1,36]],"19":[[2,22]],"30":[[2,22]],"29":[[2,22]],"28":[[2,22]],"24":[[2,22]],"33":[[2,22]],"35":[[2,22]],"38":[[2,22]],"36":[[2,22]],"12":[[2,22]],"14":[[2,22]],"5":[[2,22]],"16":[[2,22]],"20":[[2,22]]},{"34":[[1,46]]},{"7":[[1,47]]},{"1":[[2,2]]},{"5":[[2,9]],"7":[[2,9]],"36":[[2,9]],"38":[[2,9]],"35":[[2,9]],"33":[[2,9]],"19":[[2,9]],"24":[[2,9]],"28":[[2,9]],"29":[[2,9]],"30":[[2,9]]},{"30":[[2,11]],"29":[[2,11]],"28":[[2,11]],"24":[[2,11]],"19":[[2,11]],"33":[[2,11]],"35":[[2,11]],"38":[[2,11]],"36":[[2,11]],"7":[[2,11]],"5":[[2,11]]},{"16":[[1,30]],"12":[[2,14]],"14":[[2,14]],"5":[[2,14]],"20":[[2,14]]},{"19":[[2,18]],"30":[[2,18]],"29":[[2,18]],"28":[[2,18]],"24":[[2,18]],"33":[[2,18]],"35":[[2,18]],"38":[[2,18]],"36":[[2,18]],"12":[[2,18]],"14":[[2,18]],"5":[[2,18]],"16":[[2,18]],"21":[[2,18]],"22":[[2,18]],"23":[[2,18]],"37":[[2,18]],"20":[[2,18]]},{"23":[[2,31]],"22":[[2,31]],"21":[[2,31]],"16":[[2,31]],"5":[[2,31]],"14":[[2,31]],"12":[[2,31]],"36":[[2,31]],"38":[[2,31]],"35":[[2,31]],"33":[[2,31]],"24":[[2,31]],"28":[[2,31]],"29":[[2,31]],"30":[[2,31]],"19":[[2,31]],"37":[[2,31]],"20":[[2,31]]},{"1":[[2,1]]}],
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
        yy.freshLine = true;
        break;
      case 1:
        if (yy.ruleSection) {
            yy.freshLine = false;
        }
        break;
      case 2:
        yy_.yytext = yy_.yytext.substr(2, yy_.yytext.length - 3);
        return 14;
        break;
      case 3:
        return 12;
        break;
      case 4:
        yy_.yytext = yy_.yytext.replace(/\\"/g, "\"");
        return 38;
        break;
      case 5:
        yy_.yytext = yy_.yytext.replace(/\\'/g, "'");
        return 38;
        break;
      case 6:
        return 16;
        break;
      case 7:
        return 35;
        break;
      case 8:
        return 19;
        break;
      case 9:
        return 20;
        break;
      case 10:
        return 21;
        break;
      case 11:
        return 22;
        break;
      case 12:
        return 23;
        break;
      case 13:
        return 29;
        break;
      case 14:
        return 24;
        break;
      case 15:
        return 36;
        break;
      case 16:
        return 30;
        break;
      case 17:
        return 30;
        break;
      case 18:
        return 28;
        break;
      case 19:
        yy.ruleSection = true;
        return 5;
        break;
      case 20:
        return 37;
        break;
      case 21:
        if (yy.freshLine) {
            this.input("{");
            return 33;
        } else {
            this.unput("y");
        }
        break;
      case 22:
        return 34;
        break;
      case 23:
        yy_.yytext = yy_.yytext.substr(2, yy_.yytext.length - 4);
        return 14;
        break;
      case 24:
        break;
      case 25:
        return 7;
        break;
      default:;
    }
};
lexer.rules = [/^\n+/, /^\s+/, /^y\{[^}]*\}/, /^[a-zA-Z_][a-zA-Z0-9_-]*/, /^"(\\\\|\\"|[^"])*"/, /^'(\\\\|\\'|[^'])*'/, /^\|/, /^\[(\\\]|[^\]])*\]/, /^\(/, /^\)/, /^\+/, /^\*/, /^\?/, /^\^/, /^\//, /^\\[a-zA-Z0]/, /^\$/, /^<<EOF>>/, /^\./, /^%%/, /^\{\d+(,\s?\d+|,)?\}/, /^(?=\{)/, /^\}/, /^%\{(.|\n)*?%\}/, /^./, /^$/];return lexer;})()
parser.lexer = lexer;
return parser;
})();
if (typeof require !== 'undefined') {
exports.parser = jisonlex;
exports.parse = function () { return jisonlex.parse.apply(jisonlex, arguments); }
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
