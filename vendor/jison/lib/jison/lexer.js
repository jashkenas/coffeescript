// Basic RegExp Lexer 
// MIT Licensed
// Zachary Carter <zach@carter.name>

var RegExpLexer = (function () {

// expand macros and convert matchers to RegExp's
function prepareRules(rules, macros, actions, tokens) {
    var m,i,k,action,
        newRules = [];

    if (macros) {
        macros = prepareMacros(macros);
    }

    actions.push('switch(arguments[2]) {');

    for (i=0;i < rules.length; i++) {
        m = rules[i][0];
        for (k in macros) {
            if (macros.hasOwnProperty(k) && typeof m === 'string') {
                m = m.split("{"+k+"}").join(macros[k]);
            }
        }
        if (typeof m === 'string') {
            m = new RegExp("^"+m);
        }
        newRules.push(m);
        if (typeof rules[i][1] === 'function') {
            rules[i][1] = String(rules[i][1]).replace(/^\s*function \(\) \{/, '').replace(/\}\s*$/, '');
        }
        action = rules[i][1];
        if (tokens && action.match(/return '[^']+'/)) {
            action = action.replace(/return '([^']+)'/, function (str, pl) {
                        return "return "+(tokens[pl] ? tokens[pl] : "'"+pl+"'");
                    });
        }
        actions.push('case '+i+':' +action+'\nbreak;');
    }
    actions.push("}");

    return newRules;
}

// expand macros within macros
function prepareMacros (macros) {
    var cont = true,
        m,i,k,mnew;
    while (cont) {
        cont = false;
        for (i in macros) if (macros.hasOwnProperty(i)) {
            m = macros[i];
            for (k in macros) if (macros.hasOwnProperty(k) && i !== k) {
                mnew = m.split("{"+k+"}").join(macros[k]);
                if (mnew !== m) {
                    cont = true;
                    macros[i] = mnew;
                }
            }
        }
    }
    return macros;
}

function buildActions (dict, tokens) {
    var actions = [dict.actionInclude || ''];
    var tok;
    var toks = {};

    for (tok in tokens) {
        toks[tokens[tok]] = tok;
    }

    this.rules = prepareRules(dict.rules, dict.macros, actions, tokens && toks);
    var fun = actions.join("\n");
    "yytext yyleng yylineno".split(' ').forEach(function (yy) {
        fun = fun.replace(new RegExp("("+yy+")", "g"), "yy_.$1");
    });

    return Function("yy", "yy_", fun);
}

function RegExpLexer (dict, input, tokens) {
    if (typeof dict === 'string') {
        dict = require("./jisonlex").parse(dict);
    }
    dict = dict || {};

    this.performAction = buildActions.call(this, dict, tokens);

    this.yy = {};
    if (input) {
        this.setInput(input);
    }
}

RegExpLexer.prototype = {
    EOF: '',
    parseError: function parseError(str, hash) {
        if (this.yy.parseError) {
            this.yy.parseError(str, hash);
        } else {
            throw new Error(str);
        }
    },

    // resets the lexer, sets new input 
    setInput: function (input) {
        this._input = input;
        this._more = this._less = this.done = false;
        this.yylineno = this.yyleng = 0;
        this.yytext = this.matched = this.match = '';
        return this;
    },
    // consumes and returns one char from the input
    input: function () {
        var ch = this._input[0];
        this.yytext+=ch;
        this.yyleng++;
        this.match+=ch;
        this.matched+=ch;
        var lines = ch.match(/\n/);
        if (lines) this.yylineno++;
        this._input = this._input.slice(1);
        return ch;
    },
    // unshifts one char into the input
    unput: function (ch) {
        this._input = ch + this._input;
        return this;
    },
    // When called from action, caches matched text and appends it on next action
    more: function () {
        this._more = true;
        return this;
    },
    // displays upcoming input, i.e. for error messages
    pastInput: function () {
        var past = this.matched.substr(0, this.matched.length - this.match.length);
        return (past.length > 20 ? '...':'') + past.substr(-20).replace(/\n/g, "");
    },
    // displays upcoming input, i.e. for error messages
    upcomingInput: function () {
        var next = this.match;
        if (next.length < 20) {
            next += this._input.substr(0, 20-next.length);
        }
        return (next.substr(0,20)+(next.length > 20 ? '...':'')).replace(/\n/g, "");
    },
    // displays upcoming input, i.e. for error messages
    showPosition: function () {
        var pre = this.pastInput();
        var c = new Array(pre.length + 1).join("-");
        return pre + this.upcomingInput() + "\n" + c+"^";
    },

    // return next match in input
    next: function () {
        if (this.done) {
            return this.EOF;
        }
        if (!this._input) this.done = true;

        var token,
            match,
            lines;
        if (!this._more) {
            this.yytext = '';
            this.match = '';
        }
        for (var i=0;i < this.rules.length; i++) {
            match = this._input.match(this.rules[i]);
            if (match) {
                lines = match[0].match(/\n/g);
                if (lines) this.yylineno += lines.length;
                this.yytext += match[0];
                this.match += match[0];
                this.matches = match;
                this.yyleng = this.yytext.length;
                this._more = false;
                this._input = this._input.slice(match[0].length);
                this.matched += match[0];
                token = this.performAction.call(this, this.yy, this, i);
                if (token) return token;
                else return;
            }
        }
        if (this._input == this.EOF) {
            return this.EOF;
        } else {
            this.parseError('Lexical error on line '+(this.yylineno+1)+'. Unrecognized text.\n'+this.showPosition(), 
                    {text: "", token: null, line: this.yylineno});
        }
    },

    // return next match that has a token
    lex: function () {
        var r = this.next();
        if (typeof r !== 'undefined') {
            return r;
        } else {
            return this.lex();
        }
    },

    generate:  function generate(opt) {
        var code = "";
        if (opt.commonjs)
            code = this.generateCommonJSModule(opt);
        else
            code = this.generateModule(opt);

        return code;
    },
    generateModule: function generateModule(opt) {
        opt = opt || {};
        var out = "/* Jison generated lexer */",
            moduleName = opt.moduleName || "lexer";
        out += "\nvar "+moduleName+" = (function(){var lexer = ({";
        var p = [];
        for (var k in RegExpLexer.prototype)
            if (RegExpLexer.prototype.hasOwnProperty(k) && k.indexOf("generate") === -1)
            p.push(k + ":" + (RegExpLexer.prototype[k].toString() || '""'));
        out += p.join(",\n");
        out += "})";
        out += ";\nlexer.performAction = "+String(this.performAction);
        out += ";\nlexer.rules = [" + this.rules + "]";
        out += ";return lexer;})()";
        return out;
    },
    generateCommonJSModule: function generateCommonJSModule(opt) {
        opt = opt || {};
        var out = "/* Jison generated lexer as commonjs module */",
            moduleName = opt.moduleName || "lexer";
        out += this.generateModule(opt);
        out += "\nexports.lexer = "+moduleName;
        out += ";\nexports.lex = function () { return "+moduleName+".lex.apply(lexer, arguments); };";
        return out;
    }
};

return RegExpLexer;

})()

if (typeof exports !== 'undefined') 
    exports.RegExpLexer = RegExpLexer;

