!function(){

    var root = this,
        illiterate = {};

    if (typeof exports !== 'undefined') {
        if (typeof module !== 'undefined' && module.exports) {
            exports = module.exports = illiterate;
        }
    } else {
        root.illiterate = illiterate;
    }
    var _ = require('lodash'),
        marked = require('marked');
    illiterate.parse = function(text){
        var out = [];
        out.push( _.reduce(marked.lexer(text, {}), function(memo, item){
            if(item.type === 'code'){
                memo.push(item.text);
            }
            return memo;
        }, [] ).join('\n'));
        return out.join('\n');

    };
    if (typeof define === 'function' && define.amd) {
        define('illiterate', [], function() {
            return illiterate;
        });
    }

    return illiterate;
}.call(this);
