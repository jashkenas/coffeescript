if (typeof require !== 'undefined') {
    var jisonlex = require("./util/lex-parser").parser;
    exports.parse = function parse () {
        jisonlex.yy.ruleSection = false;
        return jisonlex.parse.apply(jisonlex, arguments);
    };
}

function encodeRE (s) { return s.replace(/([.*+?^${}()|[\]\/\\])/g, '\\$1'); }

jisonlex.yy = {
    prepareString: function (s) {
        // unescape slashes
        s = s.replace(/\\\\/g, "\\");
        s = encodeRE(s);
        return s;
    }
};
