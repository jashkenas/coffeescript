!function(){

    var illiterate = {};

    if (typeof exports !== 'undefined') {
        if (typeof module !== 'undefined' && module.exports) {
            exports = module.exports = illiterate;
        }
    }
    var _ = require('lodash'),
        marked = require('marked');

    illiterate.parse = function(file_contents){
        var out = [];
        out.push( _.reduce(marked.lexer(file_contents, {}), function(memo, item){
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
