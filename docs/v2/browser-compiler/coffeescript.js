/**
 * CoffeeScript Compiler v2.0.0-beta1
 * http://coffeescript.org
 *
 * Copyright 2011, Jeremy Ashkenas
 * Released under the MIT License
 */
(function(root) {
  var CoffeeScript = function() {
    function require(path){ return require[path]; }
    require['../../package.json'] = (function() {
  return {
  "name": "coffeescript",
  "description": "Unfancy JavaScript",
  "keywords": [
    "javascript",
    "language",
    "coffeescript",
    "compiler"
  ],
  "author": "Jeremy Ashkenas",
  "version": "2.0.0-beta1",
  "license": "MIT",
  "engines": {
    "node": ">=7.6.0"
  },
  "directories": {
    "lib": "./lib/coffeescript"
  },
  "main": "./lib/coffeescript/coffeescript",
  "bin": {
    "coffee": "./bin/coffee",
    "cake": "./bin/cake"
  },
  "files": [
    "bin",
    "lib",
    "register.js",
    "repl.js"
  ],
  "preferGlobal": true,
  "scripts": {
    "test": "node ./bin/cake test",
    "test-harmony": "node --harmony ./bin/cake test"
  },
  "homepage": "http://coffeescript.org",
  "bugs": "https://github.com/jashkenas/coffeescript/issues",
  "repository": {
    "type": "git",
    "url": "git://github.com/jashkenas/coffeescript.git"
  },
  "devDependencies": {
    "docco": "~0.7.0",
    "google-closure-compiler-js": "^20170409.0.0",
    "highlight.js": "~9.10.0",
    "jison": ">=0.4.17",
    "underscore": "~1.8.3"
  },
  "dependencies": {
    "markdown-it": "^8.3.1"
  }
}
;
})();require['markdown-it'] = (function() {
  var exports = {}, module = {exports: exports};
  /*! markdown-it 8.3.1 https://github.com//markdown-it/markdown-it @license MIT */
!function(e){if("object"==typeof exports&&"undefined"!=typeof module)module.exports=e();else if("function"==typeof define&&define.amd)define([],e);else{var r;r="undefined"!=typeof window?window:"undefined"!=typeof global?global:"undefined"!=typeof self?self:this,r.markdownit=e()}}(function(){var e;return function e(r,t,n){function s(i,a){if(!t[i]){if(!r[i]){var c="function"==typeof require&&require;if(!a&&c)return c(i,!0);if(o)return o(i,!0);var l=new Error("Cannot find module '"+i+"'");throw l.code="MODULE_NOT_FOUND",l}var u=t[i]={exports:{}};r[i][0].call(u.exports,function(e){var t=r[i][1][e];return s(t?t:e)},u,u.exports,e,r,t,n)}return t[i].exports}for(var o="function"==typeof require&&require,i=0;i<n.length;i++)s(n[i]);return s}({1:[function(e,r,t){"use strict";r.exports=e("entities/maps/entities.json")},{"entities/maps/entities.json":52}],2:[function(e,r,t){"use strict";r.exports=["address","article","aside","base","basefont","blockquote","body","caption","center","col","colgroup","dd","details","dialog","dir","div","dl","dt","fieldset","figcaption","figure","footer","form","frame","frameset","h1","h2","h3","h4","h5","h6","head","header","hr","html","iframe","legend","li","link","main","menu","menuitem","meta","nav","noframes","ol","optgroup","option","p","param","pre","section","source","title","summary","table","tbody","td","tfoot","th","thead","title","tr","track","ul"]},{}],3:[function(e,r,t){"use strict";var n="<[A-Za-z][A-Za-z0-9\\-]*(?:\\s+[a-zA-Z_:][a-zA-Z0-9:._-]*(?:\\s*=\\s*(?:[^\"'=<>`\\x00-\\x20]+|'[^']*'|\"[^\"]*\"))?)*\\s*\\/?>",s="<\\/[A-Za-z][A-Za-z0-9\\-]*\\s*>",o=new RegExp("^(?:"+n+"|"+s+"|<!---->|<!--(?:-?[^>-])(?:-?[^-])*-->|<[?].*?[?]>|<![A-Z]+\\s+[^>]*>|<!\\[CDATA\\[[\\s\\S]*?\\]\\]>)"),i=new RegExp("^(?:"+n+"|"+s+")");r.exports.HTML_TAG_RE=o,r.exports.HTML_OPEN_CLOSE_TAG_RE=i},{}],4:[function(e,r,t){"use strict";function n(e){return Object.prototype.toString.call(e)}function s(e){return"[object String]"===n(e)}function o(e,r){return y.call(e,r)}function i(e){return Array.prototype.slice.call(arguments,1).forEach(function(r){if(r){if("object"!=typeof r)throw new TypeError(r+"must be object");Object.keys(r).forEach(function(t){e[t]=r[t]})}}),e}function a(e,r,t){return[].concat(e.slice(0,r),t,e.slice(r+1))}function c(e){return!(e>=55296&&e<=57343)&&(!(e>=64976&&e<=65007)&&(65535!=(65535&e)&&65534!=(65535&e)&&(!(e>=0&&e<=8)&&(11!==e&&(!(e>=14&&e<=31)&&(!(e>=127&&e<=159)&&!(e>1114111)))))))}function l(e){if(e>65535){e-=65536;var r=55296+(e>>10),t=56320+(1023&e);return String.fromCharCode(r,t)}return String.fromCharCode(e)}function u(e,r){var t=0;return o(w,r)?w[r]:35===r.charCodeAt(0)&&A.test(r)&&(t="x"===r[1].toLowerCase()?parseInt(r.slice(2),16):parseInt(r.slice(1),10),c(t))?l(t):e}function p(e){return e.indexOf("\\")<0?e:e.replace(x,"$1")}function h(e){return e.indexOf("\\")<0&&e.indexOf("&")<0?e:e.replace(C,function(e,r,t){return r?r:u(e,t)})}function f(e){return q[e]}function d(e){return D.test(e)?e.replace(/[&<>"]/g,f):e}function m(e){return e.replace(/[.?*+^$[\]\\(){}|-]/g,"\\$&")}function _(e){switch(e){case 9:case 32:return!0}return!1}function g(e){if(e>=8192&&e<=8202)return!0;switch(e){case 9:case 10:case 11:case 12:case 13:case 32:case 160:case 5760:case 8239:case 8287:case 12288:return!0}return!1}function b(e){return E.test(e)}function k(e){switch(e){case 33:case 34:case 35:case 36:case 37:case 38:case 39:case 40:case 41:case 42:case 43:case 44:case 45:case 46:case 47:case 58:case 59:case 60:case 61:case 62:case 63:case 64:case 91:case 92:case 93:case 94:case 95:case 96:case 123:case 124:case 125:case 126:return!0;default:return!1}}function v(e){return e.trim().replace(/\s+/g," ").toUpperCase()}var y=Object.prototype.hasOwnProperty,x=/\\([!"#$%&'()*+,\-.\/:;<=>?@[\\\]^_`{|}~])/g,C=new RegExp(x.source+"|"+/&([a-z#][a-z0-9]{1,31});/gi.source,"gi"),A=/^#((?:x[a-f0-9]{1,8}|[0-9]{1,8}))/i,w=e("./entities"),D=/[&<>"]/,q={"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"},E=e("uc.micro/categories/P/regex");t.lib={},t.lib.mdurl=e("mdurl"),t.lib.ucmicro=e("uc.micro"),t.assign=i,t.isString=s,t.has=o,t.unescapeMd=p,t.unescapeAll=h,t.isValidEntityCode=c,t.fromCodePoint=l,t.escapeHtml=d,t.arrayReplaceAt=a,t.isSpace=_,t.isWhiteSpace=g,t.isMdAsciiPunct=k,t.isPunctChar=b,t.escapeRE=m,t.normalizeReference=v},{"./entities":1,mdurl:58,"uc.micro":65,"uc.micro/categories/P/regex":63}],5:[function(e,r,t){"use strict";t.parseLinkLabel=e("./parse_link_label"),t.parseLinkDestination=e("./parse_link_destination"),t.parseLinkTitle=e("./parse_link_title")},{"./parse_link_destination":6,"./parse_link_label":7,"./parse_link_title":8}],6:[function(e,r,t){"use strict";var n=e("../common/utils").isSpace,s=e("../common/utils").unescapeAll;r.exports=function(e,r,t){var o,i,a=r,c={ok:!1,pos:0,lines:0,str:""};if(60===e.charCodeAt(r)){for(r++;r<t;){if(10===(o=e.charCodeAt(r))||n(o))return c;if(62===o)return c.pos=r+1,c.str=s(e.slice(a+1,r)),c.ok=!0,c;92===o&&r+1<t?r+=2:r++}return c}for(i=0;r<t&&32!==(o=e.charCodeAt(r))&&!(o<32||127===o);)if(92===o&&r+1<t)r+=2;else{if(40===o&&++i>1)break;if(41===o&&--i<0)break;r++}return a===r?c:(c.str=s(e.slice(a,r)),c.lines=0,c.pos=r,c.ok=!0,c)}},{"../common/utils":4}],7:[function(e,r,t){"use strict";r.exports=function(e,r,t){var n,s,o,i,a=-1,c=e.posMax,l=e.pos;for(e.pos=r+1,n=1;e.pos<c;){if(93===(o=e.src.charCodeAt(e.pos))&&0===--n){s=!0;break}if(i=e.pos,e.md.inline.skipToken(e),91===o)if(i===e.pos-1)n++;else if(t)return e.pos=l,-1}return s&&(a=e.pos),e.pos=l,a}},{}],8:[function(e,r,t){"use strict";var n=e("../common/utils").unescapeAll;r.exports=function(e,r,t){var s,o,i=0,a=r,c={ok:!1,pos:0,lines:0,str:""};if(r>=t)return c;if(34!==(o=e.charCodeAt(r))&&39!==o&&40!==o)return c;for(r++,40===o&&(o=41);r<t;){if((s=e.charCodeAt(r))===o)return c.pos=r+1,c.lines=i,c.str=n(e.slice(a+1,r)),c.ok=!0,c;10===s?i++:92===s&&r+1<t&&(r++,10===e.charCodeAt(r)&&i++),r++}return c}},{"../common/utils":4}],9:[function(e,r,t){"use strict";function n(e){var r=e.trim().toLowerCase();return!g.test(r)||!!b.test(r)}function s(e){var r=d.parse(e,!0);if(r.hostname&&(!r.protocol||k.indexOf(r.protocol)>=0))try{r.hostname=m.toASCII(r.hostname)}catch(e){}return d.encode(d.format(r))}function o(e){var r=d.parse(e,!0);if(r.hostname&&(!r.protocol||k.indexOf(r.protocol)>=0))try{r.hostname=m.toUnicode(r.hostname)}catch(e){}return d.decode(d.format(r))}function i(e,r){if(!(this instanceof i))return new i(e,r);r||a.isString(e)||(r=e||{},e="default"),this.inline=new h,this.block=new p,this.core=new u,this.renderer=new l,this.linkify=new f,this.validateLink=n,this.normalizeLink=s,this.normalizeLinkText=o,this.utils=a,this.helpers=a.assign({},c),this.options={},this.configure(e),r&&this.set(r)}var a=e("./common/utils"),c=e("./helpers"),l=e("./renderer"),u=e("./parser_core"),p=e("./parser_block"),h=e("./parser_inline"),f=e("linkify-it"),d=e("mdurl"),m=e("punycode"),_={default:e("./presets/default"),zero:e("./presets/zero"),commonmark:e("./presets/commonmark")},g=/^(vbscript|javascript|file|data):/,b=/^data:image\/(gif|png|jpeg|webp);/,k=["http:","https:","mailto:"];i.prototype.set=function(e){return a.assign(this.options,e),this},i.prototype.configure=function(e){var r,t=this;if(a.isString(e)&&(r=e,!(e=_[r])))throw new Error('Wrong `markdown-it` preset "'+r+'", check name');if(!e)throw new Error("Wrong `markdown-it` preset, can't be empty");return e.options&&t.set(e.options),e.components&&Object.keys(e.components).forEach(function(r){e.components[r].rules&&t[r].ruler.enableOnly(e.components[r].rules),e.components[r].rules2&&t[r].ruler2.enableOnly(e.components[r].rules2)}),this},i.prototype.enable=function(e,r){var t=[];Array.isArray(e)||(e=[e]),["core","block","inline"].forEach(function(r){t=t.concat(this[r].ruler.enable(e,!0))},this),t=t.concat(this.inline.ruler2.enable(e,!0));var n=e.filter(function(e){return t.indexOf(e)<0});if(n.length&&!r)throw new Error("MarkdownIt. Failed to enable unknown rule(s): "+n);return this},i.prototype.disable=function(e,r){var t=[];Array.isArray(e)||(e=[e]),["core","block","inline"].forEach(function(r){t=t.concat(this[r].ruler.disable(e,!0))},this),t=t.concat(this.inline.ruler2.disable(e,!0));var n=e.filter(function(e){return t.indexOf(e)<0});if(n.length&&!r)throw new Error("MarkdownIt. Failed to disable unknown rule(s): "+n);return this},i.prototype.use=function(e){var r=[this].concat(Array.prototype.slice.call(arguments,1));return e.apply(e,r),this},i.prototype.parse=function(e,r){if("string"!=typeof e)throw new Error("Input data should be a String");var t=new this.core.State(e,this,r);return this.core.process(t),t.tokens},i.prototype.render=function(e,r){return r=r||{},this.renderer.render(this.parse(e,r),this.options,r)},i.prototype.parseInline=function(e,r){var t=new this.core.State(e,this,r);return t.inlineMode=!0,this.core.process(t),t.tokens},i.prototype.renderInline=function(e,r){return r=r||{},this.renderer.render(this.parseInline(e,r),this.options,r)},r.exports=i},{"./common/utils":4,"./helpers":5,"./parser_block":10,"./parser_core":11,"./parser_inline":12,"./presets/commonmark":13,"./presets/default":14,"./presets/zero":15,"./renderer":16,"linkify-it":53,mdurl:58,punycode:60}],10:[function(e,r,t){"use strict";function n(){this.ruler=new s;for(var e=0;e<o.length;e++)this.ruler.push(o[e][0],o[e][1],{alt:(o[e][2]||[]).slice()})}var s=e("./ruler"),o=[["table",e("./rules_block/table"),["paragraph","reference"]],["code",e("./rules_block/code")],["fence",e("./rules_block/fence"),["paragraph","reference","blockquote","list"]],["blockquote",e("./rules_block/blockquote"),["paragraph","reference","list"]],["hr",e("./rules_block/hr"),["paragraph","reference","blockquote","list"]],["list",e("./rules_block/list"),["paragraph","reference","blockquote"]],["reference",e("./rules_block/reference")],["heading",e("./rules_block/heading"),["paragraph","reference","blockquote"]],["lheading",e("./rules_block/lheading")],["html_block",e("./rules_block/html_block"),["paragraph","reference","blockquote"]],["paragraph",e("./rules_block/paragraph")]];n.prototype.tokenize=function(e,r,t){for(var n,s=this.ruler.getRules(""),o=s.length,i=r,a=!1,c=e.md.options.maxNesting;i<t&&(e.line=i=e.skipEmptyLines(i),!(i>=t))&&!(e.sCount[i]<e.blkIndent);){if(e.level>=c){e.line=t;break}for(n=0;n<o&&!s[n](e,i,t,!1);n++);e.tight=!a,e.isEmpty(e.line-1)&&(a=!0),(i=e.line)<t&&e.isEmpty(i)&&(a=!0,i++,e.line=i)}},n.prototype.parse=function(e,r,t,n){var s;e&&(s=new this.State(e,r,t,n),this.tokenize(s,s.line,s.lineMax))},n.prototype.State=e("./rules_block/state_block"),r.exports=n},{"./ruler":17,"./rules_block/blockquote":18,"./rules_block/code":19,"./rules_block/fence":20,"./rules_block/heading":21,"./rules_block/hr":22,"./rules_block/html_block":23,"./rules_block/lheading":24,"./rules_block/list":25,"./rules_block/paragraph":26,"./rules_block/reference":27,"./rules_block/state_block":28,"./rules_block/table":29}],11:[function(e,r,t){"use strict";function n(){this.ruler=new s;for(var e=0;e<o.length;e++)this.ruler.push(o[e][0],o[e][1])}var s=e("./ruler"),o=[["normalize",e("./rules_core/normalize")],["block",e("./rules_core/block")],["inline",e("./rules_core/inline")],["linkify",e("./rules_core/linkify")],["replacements",e("./rules_core/replacements")],["smartquotes",e("./rules_core/smartquotes")]];n.prototype.process=function(e){var r,t,n;for(n=this.ruler.getRules(""),r=0,t=n.length;r<t;r++)n[r](e)},n.prototype.State=e("./rules_core/state_core"),r.exports=n},{"./ruler":17,"./rules_core/block":30,"./rules_core/inline":31,"./rules_core/linkify":32,"./rules_core/normalize":33,"./rules_core/replacements":34,"./rules_core/smartquotes":35,"./rules_core/state_core":36}],12:[function(e,r,t){"use strict";function n(){var e;for(this.ruler=new s,e=0;e<o.length;e++)this.ruler.push(o[e][0],o[e][1]);for(this.ruler2=new s,e=0;e<i.length;e++)this.ruler2.push(i[e][0],i[e][1])}var s=e("./ruler"),o=[["text",e("./rules_inline/text")],["newline",e("./rules_inline/newline")],["escape",e("./rules_inline/escape")],["backticks",e("./rules_inline/backticks")],["strikethrough",e("./rules_inline/strikethrough").tokenize],["emphasis",e("./rules_inline/emphasis").tokenize],["link",e("./rules_inline/link")],["image",e("./rules_inline/image")],["autolink",e("./rules_inline/autolink")],["html_inline",e("./rules_inline/html_inline")],["entity",e("./rules_inline/entity")]],i=[["balance_pairs",e("./rules_inline/balance_pairs")],["strikethrough",e("./rules_inline/strikethrough").postProcess],["emphasis",e("./rules_inline/emphasis").postProcess],["text_collapse",e("./rules_inline/text_collapse")]];n.prototype.skipToken=function(e){var r,t,n=e.pos,s=this.ruler.getRules(""),o=s.length,i=e.md.options.maxNesting,a=e.cache;if(void 0!==a[n])return void(e.pos=a[n]);if(e.level<i)for(t=0;t<o&&(e.level++,r=s[t](e,!0),e.level--,!r);t++);else e.pos=e.posMax;r||e.pos++,a[n]=e.pos},n.prototype.tokenize=function(e){for(var r,t,n=this.ruler.getRules(""),s=n.length,o=e.posMax,i=e.md.options.maxNesting;e.pos<o;){if(e.level<i)for(t=0;t<s&&!(r=n[t](e,!1));t++);if(r){if(e.pos>=o)break}else e.pending+=e.src[e.pos++]}e.pending&&e.pushPending()},n.prototype.parse=function(e,r,t,n){var s,o,i,a=new this.State(e,r,t,n);for(this.tokenize(a),o=this.ruler2.getRules(""),i=o.length,s=0;s<i;s++)o[s](a)},n.prototype.State=e("./rules_inline/state_inline"),r.exports=n},{"./ruler":17,"./rules_inline/autolink":37,"./rules_inline/backticks":38,"./rules_inline/balance_pairs":39,"./rules_inline/emphasis":40,"./rules_inline/entity":41,"./rules_inline/escape":42,"./rules_inline/html_inline":43,"./rules_inline/image":44,"./rules_inline/link":45,"./rules_inline/newline":46,"./rules_inline/state_inline":47,"./rules_inline/strikethrough":48,"./rules_inline/text":49,"./rules_inline/text_collapse":50}],13:[function(e,r,t){"use strict";r.exports={options:{html:!0,xhtmlOut:!0,breaks:!1,langPrefix:"language-",linkify:!1,typographer:!1,quotes:"\u201c\u201d\u2018\u2019",highlight:null,maxNesting:20},components:{core:{rules:["normalize","block","inline"]},block:{rules:["blockquote","code","fence","heading","hr","html_block","lheading","list","reference","paragraph"]},inline:{rules:["autolink","backticks","emphasis","entity","escape","html_inline","image","link","newline","text"],rules2:["balance_pairs","emphasis","text_collapse"]}}}},{}],14:[function(e,r,t){"use strict";r.exports={options:{html:!1,xhtmlOut:!1,breaks:!1,langPrefix:"language-",linkify:!1,typographer:!1,quotes:"\u201c\u201d\u2018\u2019",highlight:null,maxNesting:100},components:{core:{},block:{},inline:{}}}},{}],15:[function(e,r,t){"use strict";r.exports={options:{html:!1,xhtmlOut:!1,breaks:!1,langPrefix:"language-",linkify:!1,typographer:!1,quotes:"\u201c\u201d\u2018\u2019",highlight:null,maxNesting:20},components:{core:{rules:["normalize","block","inline"]},block:{rules:["paragraph"]},inline:{rules:["text"],rules2:["balance_pairs","text_collapse"]}}}},{}],16:[function(e,r,t){"use strict";function n(){this.rules=s({},a)}var s=e("./common/utils").assign,o=e("./common/utils").unescapeAll,i=e("./common/utils").escapeHtml,a={};a.code_inline=function(e,r,t,n,s){var o=e[r];return"<code"+s.renderAttrs(o)+">"+i(e[r].content)+"</code>"},a.code_block=function(e,r,t,n,s){var o=e[r];return"<pre"+s.renderAttrs(o)+"><code>"+i(e[r].content)+"</code></pre>\n"},a.fence=function(e,r,t,n,s){var a,c,l,u,p=e[r],h=p.info?o(p.info).trim():"",f="";return h&&(f=h.split(/\s+/g)[0]),a=t.highlight?t.highlight(p.content,f)||i(p.content):i(p.content),0===a.indexOf("<pre")?a+"\n":h?(c=p.attrIndex("class"),l=p.attrs?p.attrs.slice():[],c<0?l.push(["class",t.langPrefix+f]):l[c][1]+=" "+t.langPrefix+f,u={attrs:l},"<pre><code"+s.renderAttrs(u)+">"+a+"</code></pre>\n"):"<pre><code"+s.renderAttrs(p)+">"+a+"</code></pre>\n"},a.image=function(e,r,t,n,s){var o=e[r];return o.attrs[o.attrIndex("alt")][1]=s.renderInlineAsText(o.children,t,n),s.renderToken(e,r,t)},a.hardbreak=function(e,r,t){return t.xhtmlOut?"<br />\n":"<br>\n"},a.softbreak=function(e,r,t){return t.breaks?t.xhtmlOut?"<br />\n":"<br>\n":"\n"},a.text=function(e,r){return i(e[r].content)},a.html_block=function(e,r){return e[r].content},a.html_inline=function(e,r){return e[r].content},n.prototype.renderAttrs=function(e){var r,t,n;if(!e.attrs)return"";for(n="",r=0,t=e.attrs.length;r<t;r++)n+=" "+i(e.attrs[r][0])+'="'+i(e.attrs[r][1])+'"';return n},n.prototype.renderToken=function(e,r,t){var n,s="",o=!1,i=e[r];return i.hidden?"":(i.block&&i.nesting!==-1&&r&&e[r-1].hidden&&(s+="\n"),s+=(i.nesting===-1?"</":"<")+i.tag,s+=this.renderAttrs(i),0===i.nesting&&t.xhtmlOut&&(s+=" /"),i.block&&(o=!0,1===i.nesting&&r+1<e.length&&(n=e[r+1],"inline"===n.type||n.hidden?o=!1:n.nesting===-1&&n.tag===i.tag&&(o=!1))),s+=o?">\n":">")},n.prototype.renderInline=function(e,r,t){for(var n,s="",o=this.rules,i=0,a=e.length;i<a;i++)n=e[i].type,s+=void 0!==o[n]?o[n](e,i,r,t,this):this.renderToken(e,i,r);return s},n.prototype.renderInlineAsText=function(e,r,t){for(var n="",s=0,o=e.length;s<o;s++)"text"===e[s].type?n+=e[s].content:"image"===e[s].type&&(n+=this.renderInlineAsText(e[s].children,r,t));return n},n.prototype.render=function(e,r,t){var n,s,o,i="",a=this.rules;for(n=0,s=e.length;n<s;n++)o=e[n].type,i+="inline"===o?this.renderInline(e[n].children,r,t):void 0!==a[o]?a[e[n].type](e,n,r,t,this):this.renderToken(e,n,r,t);return i},r.exports=n},{"./common/utils":4}],17:[function(e,r,t){"use strict";function n(){this.__rules__=[],this.__cache__=null}n.prototype.__find__=function(e){for(var r=0;r<this.__rules__.length;r++)if(this.__rules__[r].name===e)return r;return-1},n.prototype.__compile__=function(){var e=this,r=[""];e.__rules__.forEach(function(e){e.enabled&&e.alt.forEach(function(e){r.indexOf(e)<0&&r.push(e)})}),e.__cache__={},r.forEach(function(r){e.__cache__[r]=[],e.__rules__.forEach(function(t){t.enabled&&(r&&t.alt.indexOf(r)<0||e.__cache__[r].push(t.fn))})})},n.prototype.at=function(e,r,t){var n=this.__find__(e),s=t||{};if(n===-1)throw new Error("Parser rule not found: "+e);this.__rules__[n].fn=r,this.__rules__[n].alt=s.alt||[],this.__cache__=null},n.prototype.before=function(e,r,t,n){var s=this.__find__(e),o=n||{};if(s===-1)throw new Error("Parser rule not found: "+e);this.__rules__.splice(s,0,{name:r,enabled:!0,fn:t,alt:o.alt||[]}),this.__cache__=null},n.prototype.after=function(e,r,t,n){var s=this.__find__(e),o=n||{};if(s===-1)throw new Error("Parser rule not found: "+e);this.__rules__.splice(s+1,0,{name:r,enabled:!0,fn:t,alt:o.alt||[]}),this.__cache__=null},n.prototype.push=function(e,r,t){var n=t||{};this.__rules__.push({name:e,enabled:!0,fn:r,alt:n.alt||[]}),this.__cache__=null},n.prototype.enable=function(e,r){Array.isArray(e)||(e=[e]);var t=[];return e.forEach(function(e){var n=this.__find__(e);if(n<0){if(r)return;throw new Error("Rules manager: invalid rule name "+e)}this.__rules__[n].enabled=!0,t.push(e)},this),this.__cache__=null,t},n.prototype.enableOnly=function(e,r){Array.isArray(e)||(e=[e]),this.__rules__.forEach(function(e){e.enabled=!1}),this.enable(e,r)},n.prototype.disable=function(e,r){Array.isArray(e)||(e=[e]);var t=[];return e.forEach(function(e){var n=this.__find__(e);if(n<0){if(r)return;throw new Error("Rules manager: invalid rule name "+e)}this.__rules__[n].enabled=!1,t.push(e)},this),this.__cache__=null,t},n.prototype.getRules=function(e){return null===this.__cache__&&this.__compile__(),this.__cache__[e]||[]},r.exports=n},{}],18:[function(e,r,t){"use strict";var n=e("../common/utils").isSpace;r.exports=function(e,r,t,s){var o,i,a,c,l,u,p,h,f,d,m,_,g,b,k,v,y,x,C,A,w=e.lineMax,D=e.bMarks[r]+e.tShift[r],q=e.eMarks[r];if(e.sCount[r]-e.blkIndent>=4)return!1;if(62!==e.src.charCodeAt(D++))return!1;if(s)return!0;for(c=d=e.sCount[r]+D-(e.bMarks[r]+e.tShift[r]),32===e.src.charCodeAt(D)?(D++,c++,d++,o=!1,y=!0):9===e.src.charCodeAt(D)?(y=!0,(e.bsCount[r]+d)%4==3?(D++,c++,d++,o=!1):o=!0):y=!1,m=[e.bMarks[r]],e.bMarks[r]=D;D<q&&(i=e.src.charCodeAt(D),n(i));)9===i?d+=4-(d+e.bsCount[r]+(o?1:0))%4:d++,D++;for(_=[e.bsCount[r]],e.bsCount[r]=e.sCount[r]+1+(y?1:0),p=D>=q,k=[e.sCount[r]],e.sCount[r]=d-c,v=[e.tShift[r]],e.tShift[r]=D-e.bMarks[r],C=e.md.block.ruler.getRules("blockquote"),b=e.parentType,e.parentType="blockquote",f=r+1;f<t&&(l=e.sCount[f]<e.blkIndent,D=e.bMarks[f]+e.tShift[f],q=e.eMarks[f],!(D>=q));f++)if(62!==e.src.charCodeAt(D++)||l){if(p)break;for(x=!1,a=0,u=C.length;a<u;a++)if(C[a](e,f,t,!0)){x=!0;break}if(x){e.lineMax=f,0!==e.blkIndent&&(m.push(e.bMarks[f]),_.push(e.bsCount[f]),v.push(e.tShift[f]),k.push(e.sCount[f]),e.sCount[f]-=e.blkIndent);break}if(l)break;m.push(e.bMarks[f]),_.push(e.bsCount[f]),v.push(e.tShift[f]),k.push(e.sCount[f]),e.sCount[f]=-1}else{for(c=d=e.sCount[f]+D-(e.bMarks[f]+e.tShift[f]),32===e.src.charCodeAt(D)?(D++,c++,d++,o=!1,y=!0):9===e.src.charCodeAt(D)?(y=!0,(e.bsCount[f]+d)%4==3?(D++,c++,d++,o=!1):o=!0):y=!1,m.push(e.bMarks[f]),e.bMarks[f]=D;D<q&&(i=e.src.charCodeAt(D),n(i));)9===i?d+=4-(d+e.bsCount[f]+(o?1:0))%4:d++,D++;p=D>=q,_.push(e.bsCount[f]),e.bsCount[f]=e.sCount[f]+1+(y?1:0),k.push(e.sCount[f]),e.sCount[f]=d-c,v.push(e.tShift[f]),e.tShift[f]=D-e.bMarks[f]}for(g=e.blkIndent,e.blkIndent=0,A=e.push("blockquote_open","blockquote",1),A.markup=">",A.map=h=[r,0],e.md.block.tokenize(e,r,f),A=e.push("blockquote_close","blockquote",-1),A.markup=">",e.lineMax=w,e.parentType=b,h[1]=e.line,a=0;a<v.length;a++)e.bMarks[a+r]=m[a],e.tShift[a+r]=v[a],e.sCount[a+r]=k[a],e.bsCount[a+r]=_[a];return e.blkIndent=g,!0}},{"../common/utils":4}],19:[function(e,r,t){"use strict";r.exports=function(e,r,t){var n,s,o;if(e.sCount[r]-e.blkIndent<4)return!1;for(s=n=r+1;n<t;)if(e.isEmpty(n))n++;else{if(!(e.sCount[n]-e.blkIndent>=4))break;n++,s=n}return e.line=s,o=e.push("code_block","code",0),o.content=e.getLines(r,s,4+e.blkIndent,!0),o.map=[r,e.line],!0}},{}],20:[function(e,r,t){"use strict";r.exports=function(e,r,t,n){var s,o,i,a,c,l,u,p=!1,h=e.bMarks[r]+e.tShift[r],f=e.eMarks[r];if(e.sCount[r]-e.blkIndent>=4)return!1;if(h+3>f)return!1;if(126!==(s=e.src.charCodeAt(h))&&96!==s)return!1;if(c=h,h=e.skipChars(h,s),(o=h-c)<3)return!1;if(u=e.src.slice(c,h),i=e.src.slice(h,f),i.indexOf(String.fromCharCode(s))>=0)return!1;if(n)return!0;for(a=r;!(++a>=t)&&(h=c=e.bMarks[a]+e.tShift[a],f=e.eMarks[a],!(h<f&&e.sCount[a]<e.blkIndent));)if(e.src.charCodeAt(h)===s&&!(e.sCount[a]-e.blkIndent>=4||(h=e.skipChars(h,s))-c<o||(h=e.skipSpaces(h))<f)){p=!0;break}return o=e.sCount[r],e.line=a+(p?1:0),l=e.push("fence","code",0),l.info=i,l.content=e.getLines(r+1,a,o,!0),l.markup=u,l.map=[r,e.line],!0}},{}],21:[function(e,r,t){"use strict";var n=e("../common/utils").isSpace;r.exports=function(e,r,t,s){var o,i,a,c,l=e.bMarks[r]+e.tShift[r],u=e.eMarks[r];if(e.sCount[r]-e.blkIndent>=4)return!1;if(35!==(o=e.src.charCodeAt(l))||l>=u)return!1;for(i=1,o=e.src.charCodeAt(++l);35===o&&l<u&&i<=6;)i++,o=e.src.charCodeAt(++l);return!(i>6||l<u&&!n(o))&&(!!s||(u=e.skipSpacesBack(u,l),a=e.skipCharsBack(u,35,l),a>l&&n(e.src.charCodeAt(a-1))&&(u=a),e.line=r+1,c=e.push("heading_open","h"+String(i),1),c.markup="########".slice(0,i),c.map=[r,e.line],c=e.push("inline","",0),c.content=e.src.slice(l,u).trim(),c.map=[r,e.line],c.children=[],c=e.push("heading_close","h"+String(i),-1),c.markup="########".slice(0,i),!0))}},{"../common/utils":4}],22:[function(e,r,t){"use strict";var n=e("../common/utils").isSpace;r.exports=function(e,r,t,s){var o,i,a,c,l=e.bMarks[r]+e.tShift[r],u=e.eMarks[r];if(e.sCount[r]-e.blkIndent>=4)return!1;if(42!==(o=e.src.charCodeAt(l++))&&45!==o&&95!==o)return!1;for(i=1;l<u;){if((a=e.src.charCodeAt(l++))!==o&&!n(a))return!1;a===o&&i++}return!(i<3)&&(!!s||(e.line=r+1,c=e.push("hr","hr",0),c.map=[r,e.line],c.markup=Array(i+1).join(String.fromCharCode(o)),!0))}},{"../common/utils":4}],23:[function(e,r,t){"use strict";var n=e("../common/html_blocks"),s=e("../common/html_re").HTML_OPEN_CLOSE_TAG_RE,o=[[/^<(script|pre|style)(?=(\s|>|$))/i,/<\/(script|pre|style)>/i,!0],[/^<!--/,/-->/,!0],[/^<\?/,/\?>/,!0],[/^<![A-Z]/,/>/,!0],[/^<!\[CDATA\[/,/\]\]>/,!0],[new RegExp("^</?("+n.join("|")+")(?=(\\s|/?>|$))","i"),/^$/,!0],[new RegExp(s.source+"\\s*$"),/^$/,!1]];r.exports=function(e,r,t,n){var s,i,a,c,l=e.bMarks[r]+e.tShift[r],u=e.eMarks[r];if(e.sCount[r]-e.blkIndent>=4)return!1;if(!e.md.options.html)return!1;if(60!==e.src.charCodeAt(l))return!1;for(c=e.src.slice(l,u),s=0;s<o.length&&!o[s][0].test(c);s++);if(s===o.length)return!1;if(n)return o[s][2];if(i=r+1,!o[s][1].test(c))for(;i<t&&!(e.sCount[i]<e.blkIndent);i++)if(l=e.bMarks[i]+e.tShift[i],u=e.eMarks[i],c=e.src.slice(l,u),o[s][1].test(c)){0!==c.length&&i++;break}return e.line=i,a=e.push("html_block","",0),a.map=[r,i],a.content=e.getLines(r,i,e.blkIndent,!0),!0}},{"../common/html_blocks":2,"../common/html_re":3}],24:[function(e,r,t){"use strict";r.exports=function(e,r,t){var n,s,o,i,a,c,l,u,p,h,f=r+1,d=e.md.block.ruler.getRules("paragraph");if(e.sCount[r]-e.blkIndent>=4)return!1;for(h=e.parentType,e.parentType="paragraph";f<t&&!e.isEmpty(f);f++)if(!(e.sCount[f]-e.blkIndent>3)){if(e.sCount[f]>=e.blkIndent&&(c=e.bMarks[f]+e.tShift[f],l=e.eMarks[f],c<l&&(45===(p=e.src.charCodeAt(c))||61===p)&&(c=e.skipChars(c,p),(c=e.skipSpaces(c))>=l))){u=61===p?1:2;break}if(!(e.sCount[f]<0)){for(s=!1,o=0,i=d.length;o<i;o++)if(d[o](e,f,t,!0)){s=!0;break}if(s)break}}return!!u&&(n=e.getLines(r,f,e.blkIndent,!1).trim(),e.line=f+1,a=e.push("heading_open","h"+String(u),1),a.markup=String.fromCharCode(p),a.map=[r,e.line],a=e.push("inline","",0),a.content=n,a.map=[r,e.line-1],a.children=[],a=e.push("heading_close","h"+String(u),-1),a.markup=String.fromCharCode(p),e.parentType=h,!0)}},{}],25:[function(e,r,t){"use strict";function n(e,r){var t,n,s,o;return n=e.bMarks[r]+e.tShift[r],s=e.eMarks[r],t=e.src.charCodeAt(n++),42!==t&&45!==t&&43!==t?-1:n<s&&(o=e.src.charCodeAt(n),!i(o))?-1:n}function s(e,r){var t,n=e.bMarks[r]+e.tShift[r],s=n,o=e.eMarks[r];if(s+1>=o)return-1;if((t=e.src.charCodeAt(s++))<48||t>57)return-1;for(;;){if(s>=o)return-1;t=e.src.charCodeAt(s++);{if(!(t>=48&&t<=57)){if(41===t||46===t)break;return-1}if(s-n>=10)return-1}}return s<o&&(t=e.src.charCodeAt(s),!i(t))?-1:s}function o(e,r){var t,n,s=e.level+2;for(t=r+2,n=e.tokens.length-2;t<n;t++)e.tokens[t].level===s&&"paragraph_open"===e.tokens[t].type&&(e.tokens[t+2].hidden=!0,e.tokens[t].hidden=!0,t+=2)}var i=e("../common/utils").isSpace;r.exports=function(e,r,t,a){var c,l,u,p,h,f,d,m,_,g,b,k,v,y,x,C,A,w,D,q,E,S,F,L,z,T,I,R,M=!1,B=!0;if(e.sCount[r]-e.blkIndent>=4)return!1;if(a&&"paragraph"===e.parentType&&e.tShift[r]>=e.blkIndent&&(M=!0),(F=s(e,r))>=0){if(d=!0,z=e.bMarks[r]+e.tShift[r],v=Number(e.src.substr(z,F-z-1)),M&&1!==v)return!1}else{if(!((F=n(e,r))>=0))return!1;d=!1}if(M&&e.skipSpaces(F)>=e.eMarks[r])return!1;if(k=e.src.charCodeAt(F-1),a)return!0;for(b=e.tokens.length,d?(R=e.push("ordered_list_open","ol",1),1!==v&&(R.attrs=[["start",v]])):R=e.push("bullet_list_open","ul",1),R.map=g=[r,0],R.markup=String.fromCharCode(k),x=r,L=!1,I=e.md.block.ruler.getRules("list"),D=e.parentType,e.parentType="list";x<t;){for(S=F,y=e.eMarks[x],f=C=e.sCount[x]+F-(e.bMarks[r]+e.tShift[r]);S<y&&(c=e.src.charCodeAt(S),i(c));)9===c?C+=4-(C+e.bsCount[x])%4:C++,S++;if(l=S,h=l>=y?1:C-f,h>4&&(h=1),p=f+h,R=e.push("list_item_open","li",1),R.markup=String.fromCharCode(k),R.map=m=[r,0],A=e.blkIndent,E=e.tight,q=e.tShift[r],w=e.sCount[r],e.blkIndent=p,e.tight=!0,e.tShift[r]=l-e.bMarks[r],e.sCount[r]=C,l>=y&&e.isEmpty(r+1)?e.line=Math.min(e.line+2,t):e.md.block.tokenize(e,r,t,!0),e.tight&&!L||(B=!1),L=e.line-r>1&&e.isEmpty(e.line-1),e.blkIndent=A,e.tShift[r]=q,e.sCount[r]=w,e.tight=E,R=e.push("list_item_close","li",-1),R.markup=String.fromCharCode(k),x=r=e.line,m[1]=x,l=e.bMarks[r],x>=t)break;if(e.sCount[x]<e.blkIndent)break;for(T=!1,u=0,_=I.length;u<_;u++)if(I[u](e,x,t,!0)){T=!0;break}if(T)break;if(d){if((F=s(e,x))<0)break}else if((F=n(e,x))<0)break;if(k!==e.src.charCodeAt(F-1))break}return R=d?e.push("ordered_list_close","ol",-1):e.push("bullet_list_close","ul",-1),R.markup=String.fromCharCode(k),g[1]=x,e.line=x,e.parentType=D,B&&o(e,b),!0}},{"../common/utils":4}],26:[function(e,r,t){"use strict";r.exports=function(e,r){var t,n,s,o,i,a,c=r+1,l=e.md.block.ruler.getRules("paragraph"),u=e.lineMax;for(a=e.parentType,e.parentType="paragraph";c<u&&!e.isEmpty(c);c++)if(!(e.sCount[c]-e.blkIndent>3||e.sCount[c]<0)){for(n=!1,s=0,o=l.length;s<o;s++)if(l[s](e,c,u,!0)){n=!0;break}if(n)break}return t=e.getLines(r,c,e.blkIndent,!1).trim(),e.line=c,i=e.push("paragraph_open","p",1),i.map=[r,e.line],i=e.push("inline","",0),i.content=t,i.map=[r,e.line],i.children=[],i=e.push("paragraph_close","p",-1),e.parentType=a,!0}},{}],27:[function(e,r,t){"use strict";var n=e("../common/utils").normalizeReference,s=e("../common/utils").isSpace;r.exports=function(e,r,t,o){var i,a,c,l,u,p,h,f,d,m,_,g,b,k,v,y,x=0,C=e.bMarks[r]+e.tShift[r],A=e.eMarks[r],w=r+1;if(e.sCount[r]-e.blkIndent>=4)return!1;if(91!==e.src.charCodeAt(C))return!1;for(;++C<A;)if(93===e.src.charCodeAt(C)&&92!==e.src.charCodeAt(C-1)){if(C+1===A)return!1;if(58!==e.src.charCodeAt(C+1))return!1;break}for(l=e.lineMax,v=e.md.block.ruler.getRules("reference"),m=e.parentType,e.parentType="reference";w<l&&!e.isEmpty(w);w++)if(!(e.sCount[w]-e.blkIndent>3||e.sCount[w]<0)){for(k=!1,p=0,h=v.length;p<h;p++)if(v[p](e,w,l,!0)){k=!0;break}if(k)break}for(b=e.getLines(r,w,e.blkIndent,!1).trim(),A=b.length,C=1;C<A;C++){if(91===(i=b.charCodeAt(C)))return!1;if(93===i){d=C;break}10===i?x++:92===i&&++C<A&&10===b.charCodeAt(C)&&x++}if(d<0||58!==b.charCodeAt(d+1))return!1;for(C=d+2;C<A;C++)if(10===(i=b.charCodeAt(C)))x++;else if(!s(i))break;if(_=e.md.helpers.parseLinkDestination(b,C,A),!_.ok)return!1;if(u=e.md.normalizeLink(_.str),!e.md.validateLink(u))return!1;for(C=_.pos,x+=_.lines,a=C,c=x,g=C;C<A;C++)if(10===(i=b.charCodeAt(C)))x++;else if(!s(i))break;for(_=e.md.helpers.parseLinkTitle(b,C,A),C<A&&g!==C&&_.ok?(y=_.str,C=_.pos,x+=_.lines):(y="",C=a,x=c);C<A&&(i=b.charCodeAt(C),s(i));)C++;if(C<A&&10!==b.charCodeAt(C)&&y)for(y="",C=a,x=c;C<A&&(i=b.charCodeAt(C),s(i));)C++;return!(C<A&&10!==b.charCodeAt(C))&&(!!(f=n(b.slice(1,d)))&&(!!o||(void 0===e.env.references&&(e.env.references={}),void 0===e.env.references[f]&&(e.env.references[f]={title:y,href:u}),e.parentType=m,e.line=r+x+1,!0)))}},{"../common/utils":4}],28:[function(e,r,t){"use strict";function n(e,r,t,n){var s,i,a,c,l,u,p,h;for(this.src=e,this.md=r,this.env=t,this.tokens=n,this.bMarks=[],this.eMarks=[],this.tShift=[],this.sCount=[],this.bsCount=[],this.blkIndent=0,this.line=0,this.lineMax=0,this.tight=!1,this.ddIndent=-1,this.parentType="root",this.level=0,this.result="",i=this.src,h=!1,a=c=u=p=0,l=i.length;c<l;c++){if(s=i.charCodeAt(c),!h){if(o(s)){u++,9===s?p+=4-p%4:p++;continue}h=!0}10!==s&&c!==l-1||(10!==s&&c++,this.bMarks.push(a),this.eMarks.push(c),this.tShift.push(u),this.sCount.push(p),this.bsCount.push(0),h=!1,u=0,p=0,a=c+1)}this.bMarks.push(i.length),this.eMarks.push(i.length),this.tShift.push(0),this.sCount.push(0),this.bsCount.push(0),this.lineMax=this.bMarks.length-1}var s=e("../token"),o=e("../common/utils").isSpace;n.prototype.push=function(e,r,t){var n=new s(e,r,t);return n.block=!0,t<0&&this.level--,n.level=this.level,t>0&&this.level++,this.tokens.push(n),n},n.prototype.isEmpty=function(e){return this.bMarks[e]+this.tShift[e]>=this.eMarks[e]},n.prototype.skipEmptyLines=function(e){for(var r=this.lineMax;e<r&&!(this.bMarks[e]+this.tShift[e]<this.eMarks[e]);e++);return e},n.prototype.skipSpaces=function(e){for(var r,t=this.src.length;e<t&&(r=this.src.charCodeAt(e),o(r));e++);return e},n.prototype.skipSpacesBack=function(e,r){if(e<=r)return e;for(;e>r;)if(!o(this.src.charCodeAt(--e)))return e+1;return e},n.prototype.skipChars=function(e,r){for(var t=this.src.length;e<t&&this.src.charCodeAt(e)===r;e++);return e},n.prototype.skipCharsBack=function(e,r,t){if(e<=t)return e;for(;e>t;)if(r!==this.src.charCodeAt(--e))return e+1;return e},n.prototype.getLines=function(e,r,t,n){var s,i,a,c,l,u,p,h=e;if(e>=r)return"";for(u=new Array(r-e),s=0;h<r;h++,s++){for(i=0,p=c=this.bMarks[h],
l=h+1<r||n?this.eMarks[h]+1:this.eMarks[h];c<l&&i<t;){if(a=this.src.charCodeAt(c),o(a))9===a?i+=4-(i+this.bsCount[h])%4:i++;else{if(!(c-p<this.tShift[h]))break;i++}c++}u[s]=i>t?new Array(i-t+1).join(" ")+this.src.slice(c,l):this.src.slice(c,l)}return u.join("")},n.prototype.Token=s,r.exports=n},{"../common/utils":4,"../token":51}],29:[function(e,r,t){"use strict";function n(e,r){var t=e.bMarks[r]+e.blkIndent,n=e.eMarks[r];return e.src.substr(t,n-t)}function s(e){var r,t=[],n=0,s=e.length,o=0,i=0,a=!1,c=0;for(r=e.charCodeAt(n);n<s;)96===r?a?(a=!1,c=n):o%2==0&&(a=!0,c=n):124!==r||o%2!=0||a||(t.push(e.substring(i,n)),i=n+1),92===r?o++:o=0,n++,n===s&&a&&(a=!1,n=c+1),r=e.charCodeAt(n);return t.push(e.substring(i)),t}var o=e("../common/utils").isSpace;r.exports=function(e,r,t,i){var a,c,l,u,p,h,f,d,m,_,g,b;if(r+2>t)return!1;if(p=r+1,e.sCount[p]<e.blkIndent)return!1;if(e.sCount[p]-e.blkIndent>=4)return!1;if((l=e.bMarks[p]+e.tShift[p])>=e.eMarks[p])return!1;if(124!==(a=e.src.charCodeAt(l++))&&45!==a&&58!==a)return!1;for(;l<e.eMarks[p];){if(124!==(a=e.src.charCodeAt(l))&&45!==a&&58!==a&&!o(a))return!1;l++}for(c=n(e,r+1),h=c.split("|"),m=[],u=0;u<h.length;u++){if(!(_=h[u].trim())){if(0===u||u===h.length-1)continue;return!1}if(!/^:?-+:?$/.test(_))return!1;58===_.charCodeAt(_.length-1)?m.push(58===_.charCodeAt(0)?"center":"right"):58===_.charCodeAt(0)?m.push("left"):m.push("")}if(c=n(e,r).trim(),c.indexOf("|")===-1)return!1;if(e.sCount[r]-e.blkIndent>=4)return!1;if(h=s(c.replace(/^\||\|$/g,"")),(f=h.length)>m.length)return!1;if(i)return!0;for(d=e.push("table_open","table",1),d.map=g=[r,0],d=e.push("thead_open","thead",1),d.map=[r,r+1],d=e.push("tr_open","tr",1),d.map=[r,r+1],u=0;u<h.length;u++)d=e.push("th_open","th",1),d.map=[r,r+1],m[u]&&(d.attrs=[["style","text-align:"+m[u]]]),d=e.push("inline","",0),d.content=h[u].trim(),d.map=[r,r+1],d.children=[],d=e.push("th_close","th",-1);for(d=e.push("tr_close","tr",-1),d=e.push("thead_close","thead",-1),d=e.push("tbody_open","tbody",1),d.map=b=[r+2,0],p=r+2;p<t&&!(e.sCount[p]<e.blkIndent)&&(c=n(e,p).trim(),c.indexOf("|")!==-1)&&!(e.sCount[p]-e.blkIndent>=4);p++){for(h=s(c.replace(/^\||\|$/g,"")),d=e.push("tr_open","tr",1),u=0;u<f;u++)d=e.push("td_open","td",1),m[u]&&(d.attrs=[["style","text-align:"+m[u]]]),d=e.push("inline","",0),d.content=h[u]?h[u].trim():"",d.children=[],d=e.push("td_close","td",-1);d=e.push("tr_close","tr",-1)}return d=e.push("tbody_close","tbody",-1),d=e.push("table_close","table",-1),g[1]=b[1]=p,e.line=p,!0}},{"../common/utils":4}],30:[function(e,r,t){"use strict";r.exports=function(e){var r;e.inlineMode?(r=new e.Token("inline","",0),r.content=e.src,r.map=[0,1],r.children=[],e.tokens.push(r)):e.md.block.parse(e.src,e.md,e.env,e.tokens)}},{}],31:[function(e,r,t){"use strict";r.exports=function(e){var r,t,n,s=e.tokens;for(t=0,n=s.length;t<n;t++)r=s[t],"inline"===r.type&&e.md.inline.parse(r.content,e.md,e.env,r.children)}},{}],32:[function(e,r,t){"use strict";function n(e){return/^<a[>\s]/i.test(e)}function s(e){return/^<\/a\s*>/i.test(e)}var o=e("../common/utils").arrayReplaceAt;r.exports=function(e){var r,t,i,a,c,l,u,p,h,f,d,m,_,g,b,k,v,y=e.tokens;if(e.md.options.linkify)for(t=0,i=y.length;t<i;t++)if("inline"===y[t].type&&e.md.linkify.pretest(y[t].content))for(a=y[t].children,_=0,r=a.length-1;r>=0;r--)if(l=a[r],"link_close"!==l.type){if("html_inline"===l.type&&(n(l.content)&&_>0&&_--,s(l.content)&&_++),!(_>0)&&"text"===l.type&&e.md.linkify.test(l.content)){for(h=l.content,v=e.md.linkify.match(h),u=[],m=l.level,d=0,p=0;p<v.length;p++)g=v[p].url,b=e.md.normalizeLink(g),e.md.validateLink(b)&&(k=v[p].text,k=v[p].schema?"mailto:"!==v[p].schema||/^mailto:/i.test(k)?e.md.normalizeLinkText(k):e.md.normalizeLinkText("mailto:"+k).replace(/^mailto:/,""):e.md.normalizeLinkText("http://"+k).replace(/^http:\/\//,""),f=v[p].index,f>d&&(c=new e.Token("text","",0),c.content=h.slice(d,f),c.level=m,u.push(c)),c=new e.Token("link_open","a",1),c.attrs=[["href",b]],c.level=m++,c.markup="linkify",c.info="auto",u.push(c),c=new e.Token("text","",0),c.content=k,c.level=m,u.push(c),c=new e.Token("link_close","a",-1),c.level=--m,c.markup="linkify",c.info="auto",u.push(c),d=v[p].lastIndex);d<h.length&&(c=new e.Token("text","",0),c.content=h.slice(d),c.level=m,u.push(c)),y[t].children=a=o(a,r,u)}}else for(r--;a[r].level!==l.level&&"link_open"!==a[r].type;)r--}},{"../common/utils":4}],33:[function(e,r,t){"use strict";r.exports=function(e){var r;r=e.src.replace(/\r[\n\u0085]?|[\u2424\u2028\u0085]/g,"\n"),r=r.replace(/\u0000/g,"\ufffd"),e.src=r}},{}],34:[function(e,r,t){"use strict";function n(e,r){return c[r.toLowerCase()]}function s(e){var r,t,s=0;for(r=e.length-1;r>=0;r--)t=e[r],"text"!==t.type||s||(t.content=t.content.replace(/\((c|tm|r|p)\)/gi,n)),"link_open"===t.type&&"auto"===t.info&&s--,"link_close"===t.type&&"auto"===t.info&&s++}function o(e){var r,t,n=0;for(r=e.length-1;r>=0;r--)t=e[r],"text"!==t.type||n||i.test(t.content)&&(t.content=t.content.replace(/\+-/g,"\xb1").replace(/\.{2,}/g,"\u2026").replace(/([?!])\u2026/g,"$1..").replace(/([?!]){4,}/g,"$1$1$1").replace(/,{2,}/g,",").replace(/(^|[^-])---([^-]|$)/gm,"$1\u2014$2").replace(/(^|\s)--(\s|$)/gm,"$1\u2013$2").replace(/(^|[^-\s])--([^-\s]|$)/gm,"$1\u2013$2")),"link_open"===t.type&&"auto"===t.info&&n--,"link_close"===t.type&&"auto"===t.info&&n++}var i=/\+-|\.\.|\?\?\?\?|!!!!|,,|--/,a=/\((c|tm|r|p)\)/i,c={c:"\xa9",r:"\xae",p:"\xa7",tm:"\u2122"};r.exports=function(e){var r;if(e.md.options.typographer)for(r=e.tokens.length-1;r>=0;r--)"inline"===e.tokens[r].type&&(a.test(e.tokens[r].content)&&s(e.tokens[r].children),i.test(e.tokens[r].content)&&o(e.tokens[r].children))}},{}],35:[function(e,r,t){"use strict";function n(e,r,t){return e.substr(0,r)+t+e.substr(r+1)}function s(e,r){var t,s,c,u,p,h,f,d,m,_,g,b,k,v,y,x,C,A,w,D,q;for(w=[],t=0;t<e.length;t++){for(s=e[t],f=e[t].level,C=w.length-1;C>=0&&!(w[C].level<=f);C--);if(w.length=C+1,"text"===s.type){c=s.content,p=0,h=c.length;e:for(;p<h&&(l.lastIndex=p,u=l.exec(c));){if(y=x=!0,p=u.index+1,A="'"===u[0],m=32,u.index-1>=0)m=c.charCodeAt(u.index-1);else for(C=t-1;C>=0;C--)if("text"===e[C].type){m=e[C].content.charCodeAt(e[C].content.length-1);break}if(_=32,p<h)_=c.charCodeAt(p);else for(C=t+1;C<e.length;C++)if("text"===e[C].type){_=e[C].content.charCodeAt(0);break}if(g=a(m)||i(String.fromCharCode(m)),b=a(_)||i(String.fromCharCode(_)),k=o(m),v=o(_),v?y=!1:b&&(k||g||(y=!1)),k?x=!1:g&&(v||b||(x=!1)),34===_&&'"'===u[0]&&m>=48&&m<=57&&(x=y=!1),y&&x&&(y=!1,x=b),y||x){if(x)for(C=w.length-1;C>=0&&(d=w[C],!(w[C].level<f));C--)if(d.single===A&&w[C].level===f){d=w[C],A?(D=r.md.options.quotes[2],q=r.md.options.quotes[3]):(D=r.md.options.quotes[0],q=r.md.options.quotes[1]),s.content=n(s.content,u.index,q),e[d.token].content=n(e[d.token].content,d.pos,D),p+=q.length-1,d.token===t&&(p+=D.length-1),c=s.content,h=c.length,w.length=C;continue e}y?w.push({token:t,pos:u.index,single:A,level:f}):x&&A&&(s.content=n(s.content,u.index,"\u2019"))}else A&&(s.content=n(s.content,u.index,"\u2019"))}}}}var o=e("../common/utils").isWhiteSpace,i=e("../common/utils").isPunctChar,a=e("../common/utils").isMdAsciiPunct,c=/['"]/,l=/['"]/g;r.exports=function(e){var r;if(e.md.options.typographer)for(r=e.tokens.length-1;r>=0;r--)"inline"===e.tokens[r].type&&c.test(e.tokens[r].content)&&s(e.tokens[r].children,e)}},{"../common/utils":4}],36:[function(e,r,t){"use strict";function n(e,r,t){this.src=e,this.env=t,this.tokens=[],this.inlineMode=!1,this.md=r}var s=e("../token");n.prototype.Token=s,r.exports=n},{"../token":51}],37:[function(e,r,t){"use strict";var n=/^<([a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)>/,s=/^<([a-zA-Z][a-zA-Z0-9+.\-]{1,31}):([^<>\x00-\x20]*)>/;r.exports=function(e,r){var t,o,i,a,c,l,u=e.pos;return 60===e.src.charCodeAt(u)&&(t=e.src.slice(u),!(t.indexOf(">")<0)&&(s.test(t)?(o=t.match(s),a=o[0].slice(1,-1),c=e.md.normalizeLink(a),!!e.md.validateLink(c)&&(r||(l=e.push("link_open","a",1),l.attrs=[["href",c]],l.markup="autolink",l.info="auto",l=e.push("text","",0),l.content=e.md.normalizeLinkText(a),l=e.push("link_close","a",-1),l.markup="autolink",l.info="auto"),e.pos+=o[0].length,!0)):!!n.test(t)&&(i=t.match(n),a=i[0].slice(1,-1),c=e.md.normalizeLink("mailto:"+a),!!e.md.validateLink(c)&&(r||(l=e.push("link_open","a",1),l.attrs=[["href",c]],l.markup="autolink",l.info="auto",l=e.push("text","",0),l.content=e.md.normalizeLinkText(a),l=e.push("link_close","a",-1),l.markup="autolink",l.info="auto"),e.pos+=i[0].length,!0))))}},{}],38:[function(e,r,t){"use strict";r.exports=function(e,r){var t,n,s,o,i,a,c=e.pos;if(96!==e.src.charCodeAt(c))return!1;for(t=c,c++,n=e.posMax;c<n&&96===e.src.charCodeAt(c);)c++;for(s=e.src.slice(t,c),o=i=c;(o=e.src.indexOf("`",i))!==-1;){for(i=o+1;i<n&&96===e.src.charCodeAt(i);)i++;if(i-o===s.length)return r||(a=e.push("code_inline","code",0),a.markup=s,a.content=e.src.slice(c,o).replace(/[ \n]+/g," ").trim()),e.pos=i,!0}return r||(e.pending+=s),e.pos+=s.length,!0}},{}],39:[function(e,r,t){"use strict";r.exports=function(e){var r,t,n,s,o=e.delimiters,i=e.delimiters.length;for(r=0;r<i;r++)if(n=o[r],n.close)for(t=r-n.jump-1;t>=0;){if(s=o[t],s.open&&s.marker===n.marker&&s.end<0&&s.level===n.level){var a=(s.close||n.open)&&void 0!==s.length&&void 0!==n.length&&(s.length+n.length)%3==0;if(!a){n.jump=r-t,n.open=!1,s.end=r,s.jump=0;break}}t-=s.jump+1}}},{}],40:[function(e,r,t){"use strict";r.exports.tokenize=function(e,r){var t,n,s,o=e.pos,i=e.src.charCodeAt(o);if(r)return!1;if(95!==i&&42!==i)return!1;for(n=e.scanDelims(e.pos,42===i),t=0;t<n.length;t++)s=e.push("text","",0),s.content=String.fromCharCode(i),e.delimiters.push({marker:i,length:n.length,jump:t,token:e.tokens.length-1,level:e.level,end:-1,open:n.can_open,close:n.can_close});return e.pos+=n.length,!0},r.exports.postProcess=function(e){var r,t,n,s,o,i,a=e.delimiters,c=e.delimiters.length;for(r=0;r<c;r++)t=a[r],95!==t.marker&&42!==t.marker||t.end!==-1&&(n=a[t.end],i=r+1<c&&a[r+1].end===t.end-1&&a[r+1].token===t.token+1&&a[t.end-1].token===n.token-1&&a[r+1].marker===t.marker,o=String.fromCharCode(t.marker),s=e.tokens[t.token],s.type=i?"strong_open":"em_open",s.tag=i?"strong":"em",s.nesting=1,s.markup=i?o+o:o,s.content="",s=e.tokens[n.token],s.type=i?"strong_close":"em_close",s.tag=i?"strong":"em",s.nesting=-1,s.markup=i?o+o:o,s.content="",i&&(e.tokens[a[r+1].token].content="",e.tokens[a[t.end-1].token].content="",r++))}},{}],41:[function(e,r,t){"use strict";var n=e("../common/entities"),s=e("../common/utils").has,o=e("../common/utils").isValidEntityCode,i=e("../common/utils").fromCodePoint;r.exports=function(e,r){var t,a,c=e.pos,l=e.posMax;if(38!==e.src.charCodeAt(c))return!1;if(c+1<l)if(35===e.src.charCodeAt(c+1)){if(a=e.src.slice(c).match(/^&#((?:x[a-f0-9]{1,8}|[0-9]{1,8}));/i))return r||(t="x"===a[1][0].toLowerCase()?parseInt(a[1].slice(1),16):parseInt(a[1],10),e.pending+=i(o(t)?t:65533)),e.pos+=a[0].length,!0}else if((a=e.src.slice(c).match(/^&([a-z][a-z0-9]{1,31});/i))&&s(n,a[1]))return r||(e.pending+=n[a[1]]),e.pos+=a[0].length,!0;return r||(e.pending+="&"),e.pos++,!0}},{"../common/entities":1,"../common/utils":4}],42:[function(e,r,t){"use strict";for(var n=e("../common/utils").isSpace,s=[],o=0;o<256;o++)s.push(0);"\\!\"#$%&'()*+,./:;<=>?@[]^_`{|}~-".split("").forEach(function(e){s[e.charCodeAt(0)]=1}),r.exports=function(e,r){var t,o=e.pos,i=e.posMax;if(92!==e.src.charCodeAt(o))return!1;if(++o<i){if((t=e.src.charCodeAt(o))<256&&0!==s[t])return r||(e.pending+=e.src[o]),e.pos+=2,!0;if(10===t){for(r||e.push("hardbreak","br",0),o++;o<i&&(t=e.src.charCodeAt(o),n(t));)o++;return e.pos=o,!0}}return r||(e.pending+="\\"),e.pos++,!0}},{"../common/utils":4}],43:[function(e,r,t){"use strict";function n(e){var r=32|e;return r>=97&&r<=122}var s=e("../common/html_re").HTML_TAG_RE;r.exports=function(e,r){var t,o,i,a,c=e.pos;return!!e.md.options.html&&(i=e.posMax,!(60!==e.src.charCodeAt(c)||c+2>=i)&&(!(33!==(t=e.src.charCodeAt(c+1))&&63!==t&&47!==t&&!n(t))&&(!!(o=e.src.slice(c).match(s))&&(r||(a=e.push("html_inline","",0),a.content=e.src.slice(c,c+o[0].length)),e.pos+=o[0].length,!0))))}},{"../common/html_re":3}],44:[function(e,r,t){"use strict";var n=e("../common/utils").normalizeReference,s=e("../common/utils").isSpace;r.exports=function(e,r){var t,o,i,a,c,l,u,p,h,f,d,m,_,g="",b=e.pos,k=e.posMax;if(33!==e.src.charCodeAt(e.pos))return!1;if(91!==e.src.charCodeAt(e.pos+1))return!1;if(l=e.pos+2,(c=e.md.helpers.parseLinkLabel(e,e.pos+1,!1))<0)return!1;if((u=c+1)<k&&40===e.src.charCodeAt(u)){for(u++;u<k&&(o=e.src.charCodeAt(u),s(o)||10===o);u++);if(u>=k)return!1;for(_=u,h=e.md.helpers.parseLinkDestination(e.src,u,e.posMax),h.ok&&(g=e.md.normalizeLink(h.str),e.md.validateLink(g)?u=h.pos:g=""),_=u;u<k&&(o=e.src.charCodeAt(u),s(o)||10===o);u++);if(h=e.md.helpers.parseLinkTitle(e.src,u,e.posMax),u<k&&_!==u&&h.ok)for(f=h.str,u=h.pos;u<k&&(o=e.src.charCodeAt(u),s(o)||10===o);u++);else f="";if(u>=k||41!==e.src.charCodeAt(u))return e.pos=b,!1;u++}else{if(void 0===e.env.references)return!1;if(u<k&&91===e.src.charCodeAt(u)?(_=u+1,u=e.md.helpers.parseLinkLabel(e,u),u>=0?a=e.src.slice(_,u++):u=c+1):u=c+1,a||(a=e.src.slice(l,c)),!(p=e.env.references[n(a)]))return e.pos=b,!1;g=p.href,f=p.title}return r||(i=e.src.slice(l,c),e.md.inline.parse(i,e.md,e.env,m=[]),d=e.push("image","img",0),d.attrs=t=[["src",g],["alt",""]],d.children=m,d.content=i,f&&t.push(["title",f])),e.pos=u,e.posMax=k,!0}},{"../common/utils":4}],45:[function(e,r,t){"use strict";var n=e("../common/utils").normalizeReference,s=e("../common/utils").isSpace;r.exports=function(e,r){var t,o,i,a,c,l,u,p,h,f,d="",m=e.pos,_=e.posMax,g=e.pos,b=!0;if(91!==e.src.charCodeAt(e.pos))return!1;if(c=e.pos+1,(a=e.md.helpers.parseLinkLabel(e,e.pos,!0))<0)return!1;if((l=a+1)<_&&40===e.src.charCodeAt(l)){for(b=!1,l++;l<_&&(o=e.src.charCodeAt(l),s(o)||10===o);l++);if(l>=_)return!1;for(g=l,u=e.md.helpers.parseLinkDestination(e.src,l,e.posMax),u.ok&&(d=e.md.normalizeLink(u.str),e.md.validateLink(d)?l=u.pos:d=""),g=l;l<_&&(o=e.src.charCodeAt(l),s(o)||10===o);l++);if(u=e.md.helpers.parseLinkTitle(e.src,l,e.posMax),l<_&&g!==l&&u.ok)for(h=u.str,l=u.pos;l<_&&(o=e.src.charCodeAt(l),s(o)||10===o);l++);else h="";(l>=_||41!==e.src.charCodeAt(l))&&(b=!0),l++}if(b){if(void 0===e.env.references)return!1;if(l<_&&91===e.src.charCodeAt(l)?(g=l+1,l=e.md.helpers.parseLinkLabel(e,l),l>=0?i=e.src.slice(g,l++):l=a+1):l=a+1,i||(i=e.src.slice(c,a)),!(p=e.env.references[n(i)]))return e.pos=m,!1;d=p.href,h=p.title}return r||(e.pos=c,e.posMax=a,f=e.push("link_open","a",1),f.attrs=t=[["href",d]],h&&t.push(["title",h]),e.md.inline.tokenize(e),f=e.push("link_close","a",-1)),e.pos=l,e.posMax=_,!0}},{"../common/utils":4}],46:[function(e,r,t){"use strict";var n=e("../common/utils").isSpace;r.exports=function(e,r){var t,s,o=e.pos;if(10!==e.src.charCodeAt(o))return!1;for(t=e.pending.length-1,s=e.posMax,r||(t>=0&&32===e.pending.charCodeAt(t)?t>=1&&32===e.pending.charCodeAt(t-1)?(e.pending=e.pending.replace(/ +$/,""),e.push("hardbreak","br",0)):(e.pending=e.pending.slice(0,-1),e.push("softbreak","br",0)):e.push("softbreak","br",0)),o++;o<s&&n(e.src.charCodeAt(o));)o++;return e.pos=o,!0}},{"../common/utils":4}],47:[function(e,r,t){"use strict";function n(e,r,t,n){this.src=e,this.env=t,this.md=r,this.tokens=n,this.pos=0,this.posMax=this.src.length,this.level=0,this.pending="",this.pendingLevel=0,this.cache={},this.delimiters=[]}var s=e("../token"),o=e("../common/utils").isWhiteSpace,i=e("../common/utils").isPunctChar,a=e("../common/utils").isMdAsciiPunct;n.prototype.pushPending=function(){var e=new s("text","",0);return e.content=this.pending,e.level=this.pendingLevel,this.tokens.push(e),this.pending="",e},n.prototype.push=function(e,r,t){this.pending&&this.pushPending();var n=new s(e,r,t);return t<0&&this.level--,n.level=this.level,t>0&&this.level++,this.pendingLevel=this.level,this.tokens.push(n),n},n.prototype.scanDelims=function(e,r){var t,n,s,c,l,u,p,h,f,d=e,m=!0,_=!0,g=this.posMax,b=this.src.charCodeAt(e);for(t=e>0?this.src.charCodeAt(e-1):32;d<g&&this.src.charCodeAt(d)===b;)d++;return s=d-e,n=d<g?this.src.charCodeAt(d):32,p=a(t)||i(String.fromCharCode(t)),f=a(n)||i(String.fromCharCode(n)),u=o(t),h=o(n),h?m=!1:f&&(u||p||(m=!1)),u?_=!1:p&&(h||f||(_=!1)),r?(c=m,l=_):(c=m&&(!_||p),l=_&&(!m||f)),{can_open:c,can_close:l,length:s}},n.prototype.Token=s,r.exports=n},{"../common/utils":4,"../token":51}],48:[function(e,r,t){"use strict";r.exports.tokenize=function(e,r){var t,n,s,o,i,a=e.pos,c=e.src.charCodeAt(a);if(r)return!1;if(126!==c)return!1;if(n=e.scanDelims(e.pos,!0),o=n.length,i=String.fromCharCode(c),o<2)return!1;for(o%2&&(s=e.push("text","",0),s.content=i,o--),t=0;t<o;t+=2)s=e.push("text","",0),s.content=i+i,e.delimiters.push({marker:c,jump:t,token:e.tokens.length-1,level:e.level,end:-1,open:n.can_open,close:n.can_close});return e.pos+=n.length,!0},r.exports.postProcess=function(e){var r,t,n,s,o,i=[],a=e.delimiters,c=e.delimiters.length;for(r=0;r<c;r++)n=a[r],126===n.marker&&n.end!==-1&&(s=a[n.end],o=e.tokens[n.token],o.type="s_open",o.tag="s",o.nesting=1,o.markup="~~",o.content="",o=e.tokens[s.token],o.type="s_close",o.tag="s",o.nesting=-1,o.markup="~~",o.content="","text"===e.tokens[s.token-1].type&&"~"===e.tokens[s.token-1].content&&i.push(s.token-1));for(;i.length;){for(r=i.pop(),t=r+1;t<e.tokens.length&&"s_close"===e.tokens[t].type;)t++;t--,r!==t&&(o=e.tokens[t],e.tokens[t]=e.tokens[r],e.tokens[r]=o)}}},{}],49:[function(e,r,t){"use strict";function n(e){switch(e){case 10:case 33:case 35:case 36:case 37:case 38:case 42:case 43:case 45:case 58:case 60:case 61:case 62:case 64:case 91:case 92:case 93:case 94:case 95:case 96:case 123:case 125:case 126:return!0;default:return!1}}r.exports=function(e,r){for(var t=e.pos;t<e.posMax&&!n(e.src.charCodeAt(t));)t++;return t!==e.pos&&(r||(e.pending+=e.src.slice(e.pos,t)),e.pos=t,!0)}},{}],50:[function(e,r,t){"use strict";r.exports=function(e){var r,t,n=0,s=e.tokens,o=e.tokens.length;for(r=t=0;r<o;r++)n+=s[r].nesting,s[r].level=n,"text"===s[r].type&&r+1<o&&"text"===s[r+1].type?s[r+1].content=s[r].content+s[r+1].content:(r!==t&&(s[t]=s[r]),t++);r!==t&&(s.length=t)}},{}],51:[function(e,r,t){"use strict";function n(e,r,t){this.type=e,this.tag=r,this.attrs=null,this.map=null,this.nesting=t,this.level=0,this.children=null,this.content="",this.markup="",this.info="",this.meta=null,this.block=!1,this.hidden=!1}n.prototype.attrIndex=function(e){var r,t,n;if(!this.attrs)return-1;for(r=this.attrs,t=0,n=r.length;t<n;t++)if(r[t][0]===e)return t;return-1},n.prototype.attrPush=function(e){this.attrs?this.attrs.push(e):this.attrs=[e]},n.prototype.attrSet=function(e,r){var t=this.attrIndex(e),n=[e,r];t<0?this.attrPush(n):this.attrs[t]=n},n.prototype.attrGet=function(e){var r=this.attrIndex(e),t=null;return r>=0&&(t=this.attrs[r][1]),t},n.prototype.attrJoin=function(e,r){var t=this.attrIndex(e);t<0?this.attrPush([e,r]):this.attrs[t][1]=this.attrs[t][1]+" "+r},r.exports=n},{}],52:[function(e,r,t){r.exports={Aacute:"\xc1",aacute:"\xe1",Abreve:"\u0102",abreve:"\u0103",ac:"\u223e",acd:"\u223f",acE:"\u223e\u0333",Acirc:"\xc2",acirc:"\xe2",acute:"\xb4",Acy:"\u0410",acy:"\u0430",AElig:"\xc6",aelig:"\xe6",af:"\u2061",Afr:"\ud835\udd04",afr:"\ud835\udd1e",Agrave:"\xc0",agrave:"\xe0",alefsym:"\u2135",aleph:"\u2135",Alpha:"\u0391",alpha:"\u03b1",Amacr:"\u0100",amacr:"\u0101",amalg:"\u2a3f",amp:"&",AMP:"&",andand:"\u2a55",And:"\u2a53",and:"\u2227",andd:"\u2a5c",andslope:"\u2a58",andv:"\u2a5a",ang:"\u2220",ange:"\u29a4",angle:"\u2220",angmsdaa:"\u29a8",angmsdab:"\u29a9",angmsdac:"\u29aa",angmsdad:"\u29ab",angmsdae:"\u29ac",angmsdaf:"\u29ad",angmsdag:"\u29ae",angmsdah:"\u29af",angmsd:"\u2221",angrt:"\u221f",angrtvb:"\u22be",angrtvbd:"\u299d",angsph:"\u2222",angst:"\xc5",angzarr:"\u237c",Aogon:"\u0104",aogon:"\u0105",Aopf:"\ud835\udd38",aopf:"\ud835\udd52",apacir:"\u2a6f",ap:"\u2248",apE:"\u2a70",ape:"\u224a",apid:"\u224b",apos:"'",ApplyFunction:"\u2061",approx:"\u2248",approxeq:"\u224a",Aring:"\xc5",aring:"\xe5",Ascr:"\ud835\udc9c",ascr:"\ud835\udcb6",Assign:"\u2254",ast:"*",asymp:"\u2248",asympeq:"\u224d",Atilde:"\xc3",atilde:"\xe3",Auml:"\xc4",auml:"\xe4",awconint:"\u2233",awint:"\u2a11",backcong:"\u224c",backepsilon:"\u03f6",backprime:"\u2035",backsim:"\u223d",backsimeq:"\u22cd",Backslash:"\u2216",Barv:"\u2ae7",barvee:"\u22bd",barwed:"\u2305",Barwed:"\u2306",barwedge:"\u2305",bbrk:"\u23b5",bbrktbrk:"\u23b6",bcong:"\u224c",Bcy:"\u0411",bcy:"\u0431",bdquo:"\u201e",becaus:"\u2235",because:"\u2235",Because:"\u2235",bemptyv:"\u29b0",bepsi:"\u03f6",bernou:"\u212c",Bernoullis:"\u212c",Beta:"\u0392",beta:"\u03b2",beth:"\u2136",between:"\u226c",Bfr:"\ud835\udd05",bfr:"\ud835\udd1f",bigcap:"\u22c2",bigcirc:"\u25ef",bigcup:"\u22c3",bigodot:"\u2a00",bigoplus:"\u2a01",bigotimes:"\u2a02",bigsqcup:"\u2a06",bigstar:"\u2605",bigtriangledown:"\u25bd",bigtriangleup:"\u25b3",biguplus:"\u2a04",bigvee:"\u22c1",bigwedge:"\u22c0",bkarow:"\u290d",blacklozenge:"\u29eb",blacksquare:"\u25aa",blacktriangle:"\u25b4",blacktriangledown:"\u25be",blacktriangleleft:"\u25c2",blacktriangleright:"\u25b8",blank:"\u2423",blk12:"\u2592",blk14:"\u2591",blk34:"\u2593",block:"\u2588",bne:"=\u20e5",bnequiv:"\u2261\u20e5",bNot:"\u2aed",bnot:"\u2310",Bopf:"\ud835\udd39",bopf:"\ud835\udd53",bot:"\u22a5",bottom:"\u22a5",bowtie:"\u22c8",boxbox:"\u29c9",boxdl:"\u2510",boxdL:"\u2555",boxDl:"\u2556",boxDL:"\u2557",boxdr:"\u250c",boxdR:"\u2552",boxDr:"\u2553",boxDR:"\u2554",boxh:"\u2500",boxH:"\u2550",boxhd:"\u252c",boxHd:"\u2564",boxhD:"\u2565",boxHD:"\u2566",boxhu:"\u2534",boxHu:"\u2567",boxhU:"\u2568",boxHU:"\u2569",boxminus:"\u229f",boxplus:"\u229e",boxtimes:"\u22a0",boxul:"\u2518",boxuL:"\u255b",boxUl:"\u255c",boxUL:"\u255d",boxur:"\u2514",boxuR:"\u2558",boxUr:"\u2559",boxUR:"\u255a",boxv:"\u2502",boxV:"\u2551",boxvh:"\u253c",boxvH:"\u256a",boxVh:"\u256b",boxVH:"\u256c",boxvl:"\u2524",boxvL:"\u2561",boxVl:"\u2562",boxVL:"\u2563",boxvr:"\u251c",boxvR:"\u255e",boxVr:"\u255f",boxVR:"\u2560",bprime:"\u2035",breve:"\u02d8",Breve:"\u02d8",brvbar:"\xa6",bscr:"\ud835\udcb7",Bscr:"\u212c",bsemi:"\u204f",bsim:"\u223d",bsime:"\u22cd",bsolb:"\u29c5",bsol:"\\",bsolhsub:"\u27c8",bull:"\u2022",bullet:"\u2022",bump:"\u224e",bumpE:"\u2aae",bumpe:"\u224f",Bumpeq:"\u224e",bumpeq:"\u224f",Cacute:"\u0106",cacute:"\u0107",capand:"\u2a44",capbrcup:"\u2a49",capcap:"\u2a4b",cap:"\u2229",Cap:"\u22d2",capcup:"\u2a47",capdot:"\u2a40",CapitalDifferentialD:"\u2145",caps:"\u2229\ufe00",caret:"\u2041",caron:"\u02c7",Cayleys:"\u212d",ccaps:"\u2a4d",Ccaron:"\u010c",ccaron:"\u010d",Ccedil:"\xc7",ccedil:"\xe7",Ccirc:"\u0108",ccirc:"\u0109",Cconint:"\u2230",ccups:"\u2a4c",ccupssm:"\u2a50",Cdot:"\u010a",cdot:"\u010b",cedil:"\xb8",Cedilla:"\xb8",cemptyv:"\u29b2",cent:"\xa2",centerdot:"\xb7",CenterDot:"\xb7",cfr:"\ud835\udd20",Cfr:"\u212d",CHcy:"\u0427",chcy:"\u0447",check:"\u2713",checkmark:"\u2713",Chi:"\u03a7",chi:"\u03c7",circ:"\u02c6",circeq:"\u2257",circlearrowleft:"\u21ba",circlearrowright:"\u21bb",circledast:"\u229b",circledcirc:"\u229a",circleddash:"\u229d",CircleDot:"\u2299",circledR:"\xae",circledS:"\u24c8",CircleMinus:"\u2296",CirclePlus:"\u2295",CircleTimes:"\u2297",cir:"\u25cb",cirE:"\u29c3",cire:"\u2257",cirfnint:"\u2a10",cirmid:"\u2aef",cirscir:"\u29c2",ClockwiseContourIntegral:"\u2232",CloseCurlyDoubleQuote:"\u201d",CloseCurlyQuote:"\u2019",clubs:"\u2663",clubsuit:"\u2663",colon:":",Colon:"\u2237",Colone:"\u2a74",colone:"\u2254",coloneq:"\u2254",comma:",",commat:"@",comp:"\u2201",compfn:"\u2218",complement:"\u2201",complexes:"\u2102",cong:"\u2245",congdot:"\u2a6d",Congruent:"\u2261",conint:"\u222e",Conint:"\u222f",ContourIntegral:"\u222e",copf:"\ud835\udd54",Copf:"\u2102",coprod:"\u2210",Coproduct:"\u2210",copy:"\xa9",COPY:"\xa9",copysr:"\u2117",CounterClockwiseContourIntegral:"\u2233",crarr:"\u21b5",cross:"\u2717",Cross:"\u2a2f",Cscr:"\ud835\udc9e",cscr:"\ud835\udcb8",csub:"\u2acf",csube:"\u2ad1",csup:"\u2ad0",csupe:"\u2ad2",ctdot:"\u22ef",cudarrl:"\u2938",cudarrr:"\u2935",cuepr:"\u22de",cuesc:"\u22df",cularr:"\u21b6",cularrp:"\u293d",cupbrcap:"\u2a48",cupcap:"\u2a46",CupCap:"\u224d",cup:"\u222a",Cup:"\u22d3",cupcup:"\u2a4a",cupdot:"\u228d",cupor:"\u2a45",cups:"\u222a\ufe00",curarr:"\u21b7",curarrm:"\u293c",curlyeqprec:"\u22de",curlyeqsucc:"\u22df",curlyvee:"\u22ce",curlywedge:"\u22cf",curren:"\xa4",curvearrowleft:"\u21b6",curvearrowright:"\u21b7",cuvee:"\u22ce",cuwed:"\u22cf",cwconint:"\u2232",cwint:"\u2231",cylcty:"\u232d",dagger:"\u2020",Dagger:"\u2021",daleth:"\u2138",darr:"\u2193",Darr:"\u21a1",dArr:"\u21d3",dash:"\u2010",Dashv:"\u2ae4",dashv:"\u22a3",dbkarow:"\u290f",dblac:"\u02dd",Dcaron:"\u010e",dcaron:"\u010f",Dcy:"\u0414",dcy:"\u0434",ddagger:"\u2021",ddarr:"\u21ca",DD:"\u2145",dd:"\u2146",DDotrahd:"\u2911",ddotseq:"\u2a77",deg:"\xb0",Del:"\u2207",Delta:"\u0394",delta:"\u03b4",demptyv:"\u29b1",dfisht:"\u297f",Dfr:"\ud835\udd07",dfr:"\ud835\udd21",dHar:"\u2965",dharl:"\u21c3",dharr:"\u21c2",DiacriticalAcute:"\xb4",DiacriticalDot:"\u02d9",DiacriticalDoubleAcute:"\u02dd",DiacriticalGrave:"`",DiacriticalTilde:"\u02dc",diam:"\u22c4",diamond:"\u22c4",Diamond:"\u22c4",diamondsuit:"\u2666",diams:"\u2666",die:"\xa8",DifferentialD:"\u2146",digamma:"\u03dd",disin:"\u22f2",div:"\xf7",divide:"\xf7",divideontimes:"\u22c7",divonx:"\u22c7",DJcy:"\u0402",djcy:"\u0452",dlcorn:"\u231e",dlcrop:"\u230d",dollar:"$",Dopf:"\ud835\udd3b",dopf:"\ud835\udd55",Dot:"\xa8",dot:"\u02d9",DotDot:"\u20dc",doteq:"\u2250",doteqdot:"\u2251",DotEqual:"\u2250",dotminus:"\u2238",dotplus:"\u2214",dotsquare:"\u22a1",doublebarwedge:"\u2306",DoubleContourIntegral:"\u222f",DoubleDot:"\xa8",DoubleDownArrow:"\u21d3",DoubleLeftArrow:"\u21d0",DoubleLeftRightArrow:"\u21d4",DoubleLeftTee:"\u2ae4",DoubleLongLeftArrow:"\u27f8",DoubleLongLeftRightArrow:"\u27fa",DoubleLongRightArrow:"\u27f9",DoubleRightArrow:"\u21d2",DoubleRightTee:"\u22a8",DoubleUpArrow:"\u21d1",DoubleUpDownArrow:"\u21d5",DoubleVerticalBar:"\u2225",DownArrowBar:"\u2913",downarrow:"\u2193",DownArrow:"\u2193",Downarrow:"\u21d3",DownArrowUpArrow:"\u21f5",DownBreve:"\u0311",downdownarrows:"\u21ca",downharpoonleft:"\u21c3",downharpoonright:"\u21c2",DownLeftRightVector:"\u2950",DownLeftTeeVector:"\u295e",DownLeftVectorBar:"\u2956",DownLeftVector:"\u21bd",DownRightTeeVector:"\u295f",DownRightVectorBar:"\u2957",DownRightVector:"\u21c1",DownTeeArrow:"\u21a7",DownTee:"\u22a4",drbkarow:"\u2910",drcorn:"\u231f",drcrop:"\u230c",Dscr:"\ud835\udc9f",dscr:"\ud835\udcb9",DScy:"\u0405",dscy:"\u0455",dsol:"\u29f6",Dstrok:"\u0110",dstrok:"\u0111",dtdot:"\u22f1",dtri:"\u25bf",dtrif:"\u25be",duarr:"\u21f5",duhar:"\u296f",dwangle:"\u29a6",DZcy:"\u040f",dzcy:"\u045f",dzigrarr:"\u27ff",Eacute:"\xc9",eacute:"\xe9",easter:"\u2a6e",Ecaron:"\u011a",ecaron:"\u011b",Ecirc:"\xca",ecirc:"\xea",ecir:"\u2256",ecolon:"\u2255",Ecy:"\u042d",ecy:"\u044d",eDDot:"\u2a77",Edot:"\u0116",edot:"\u0117",eDot:"\u2251",ee:"\u2147",efDot:"\u2252",Efr:"\ud835\udd08",efr:"\ud835\udd22",eg:"\u2a9a",Egrave:"\xc8",egrave:"\xe8",egs:"\u2a96",egsdot:"\u2a98",el:"\u2a99",Element:"\u2208",elinters:"\u23e7",ell:"\u2113",els:"\u2a95",elsdot:"\u2a97",Emacr:"\u0112",emacr:"\u0113",empty:"\u2205",emptyset:"\u2205",EmptySmallSquare:"\u25fb",emptyv:"\u2205",EmptyVerySmallSquare:"\u25ab",emsp13:"\u2004",emsp14:"\u2005",emsp:"\u2003",ENG:"\u014a",eng:"\u014b",ensp:"\u2002",Eogon:"\u0118",eogon:"\u0119",Eopf:"\ud835\udd3c",eopf:"\ud835\udd56",epar:"\u22d5",eparsl:"\u29e3",eplus:"\u2a71",epsi:"\u03b5",Epsilon:"\u0395",epsilon:"\u03b5",epsiv:"\u03f5",eqcirc:"\u2256",eqcolon:"\u2255",eqsim:"\u2242",eqslantgtr:"\u2a96",eqslantless:"\u2a95",Equal:"\u2a75",equals:"=",EqualTilde:"\u2242",equest:"\u225f",Equilibrium:"\u21cc",equiv:"\u2261",equivDD:"\u2a78",eqvparsl:"\u29e5",erarr:"\u2971",erDot:"\u2253",escr:"\u212f",Escr:"\u2130",esdot:"\u2250",Esim:"\u2a73",esim:"\u2242",Eta:"\u0397",eta:"\u03b7",ETH:"\xd0",eth:"\xf0",Euml:"\xcb",euml:"\xeb",euro:"\u20ac",excl:"!",exist:"\u2203",Exists:"\u2203",expectation:"\u2130",exponentiale:"\u2147",ExponentialE:"\u2147",fallingdotseq:"\u2252",Fcy:"\u0424",fcy:"\u0444",female:"\u2640",ffilig:"\ufb03",fflig:"\ufb00",ffllig:"\ufb04",Ffr:"\ud835\udd09",ffr:"\ud835\udd23",filig:"\ufb01",FilledSmallSquare:"\u25fc",FilledVerySmallSquare:"\u25aa",fjlig:"fj",flat:"\u266d",fllig:"\ufb02",fltns:"\u25b1",fnof:"\u0192",Fopf:"\ud835\udd3d",fopf:"\ud835\udd57",forall:"\u2200",ForAll:"\u2200",fork:"\u22d4",forkv:"\u2ad9",Fouriertrf:"\u2131",fpartint:"\u2a0d",frac12:"\xbd",frac13:"\u2153",frac14:"\xbc",frac15:"\u2155",frac16:"\u2159",frac18:"\u215b",frac23:"\u2154",frac25:"\u2156",frac34:"\xbe",frac35:"\u2157",frac38:"\u215c",frac45:"\u2158",frac56:"\u215a",frac58:"\u215d",frac78:"\u215e",frasl:"\u2044",frown:"\u2322",fscr:"\ud835\udcbb",Fscr:"\u2131",gacute:"\u01f5",Gamma:"\u0393",gamma:"\u03b3",Gammad:"\u03dc",gammad:"\u03dd",gap:"\u2a86",Gbreve:"\u011e",gbreve:"\u011f",Gcedil:"\u0122",Gcirc:"\u011c",gcirc:"\u011d",Gcy:"\u0413",gcy:"\u0433",Gdot:"\u0120",gdot:"\u0121",ge:"\u2265",gE:"\u2267",gEl:"\u2a8c",gel:"\u22db",geq:"\u2265",geqq:"\u2267",geqslant:"\u2a7e",gescc:"\u2aa9",ges:"\u2a7e",gesdot:"\u2a80",gesdoto:"\u2a82",gesdotol:"\u2a84",gesl:"\u22db\ufe00",gesles:"\u2a94",Gfr:"\ud835\udd0a",gfr:"\ud835\udd24",gg:"\u226b",Gg:"\u22d9",ggg:"\u22d9",gimel:"\u2137",GJcy:"\u0403",gjcy:"\u0453",gla:"\u2aa5",gl:"\u2277",glE:"\u2a92",glj:"\u2aa4",gnap:"\u2a8a",gnapprox:"\u2a8a",gne:"\u2a88",gnE:"\u2269",gneq:"\u2a88",gneqq:"\u2269",gnsim:"\u22e7",Gopf:"\ud835\udd3e",gopf:"\ud835\udd58",grave:"`",GreaterEqual:"\u2265",GreaterEqualLess:"\u22db",GreaterFullEqual:"\u2267",GreaterGreater:"\u2aa2",GreaterLess:"\u2277",GreaterSlantEqual:"\u2a7e",GreaterTilde:"\u2273",Gscr:"\ud835\udca2",gscr:"\u210a",gsim:"\u2273",gsime:"\u2a8e",gsiml:"\u2a90",gtcc:"\u2aa7",gtcir:"\u2a7a",gt:">",GT:">",Gt:"\u226b",gtdot:"\u22d7",gtlPar:"\u2995",gtquest:"\u2a7c",gtrapprox:"\u2a86",gtrarr:"\u2978",gtrdot:"\u22d7",gtreqless:"\u22db",gtreqqless:"\u2a8c",gtrless:"\u2277",gtrsim:"\u2273",gvertneqq:"\u2269\ufe00",gvnE:"\u2269\ufe00",Hacek:"\u02c7",hairsp:"\u200a",half:"\xbd",hamilt:"\u210b",HARDcy:"\u042a",hardcy:"\u044a",harrcir:"\u2948",harr:"\u2194",hArr:"\u21d4",harrw:"\u21ad",Hat:"^",hbar:"\u210f",Hcirc:"\u0124",hcirc:"\u0125",hearts:"\u2665",heartsuit:"\u2665",hellip:"\u2026",hercon:"\u22b9",hfr:"\ud835\udd25",Hfr:"\u210c",HilbertSpace:"\u210b",hksearow:"\u2925",hkswarow:"\u2926",hoarr:"\u21ff",homtht:"\u223b",hookleftarrow:"\u21a9",hookrightarrow:"\u21aa",hopf:"\ud835\udd59",Hopf:"\u210d",horbar:"\u2015",HorizontalLine:"\u2500",hscr:"\ud835\udcbd",Hscr:"\u210b",hslash:"\u210f",Hstrok:"\u0126",hstrok:"\u0127",HumpDownHump:"\u224e",HumpEqual:"\u224f",hybull:"\u2043",hyphen:"\u2010",Iacute:"\xcd",iacute:"\xed",ic:"\u2063",Icirc:"\xce",icirc:"\xee",Icy:"\u0418",icy:"\u0438",Idot:"\u0130",IEcy:"\u0415",iecy:"\u0435",iexcl:"\xa1",iff:"\u21d4",ifr:"\ud835\udd26",Ifr:"\u2111",Igrave:"\xcc",igrave:"\xec",ii:"\u2148",iiiint:"\u2a0c",iiint:"\u222d",iinfin:"\u29dc",iiota:"\u2129",IJlig:"\u0132",ijlig:"\u0133",Imacr:"\u012a",imacr:"\u012b",image:"\u2111",ImaginaryI:"\u2148",imagline:"\u2110",imagpart:"\u2111",imath:"\u0131",Im:"\u2111",imof:"\u22b7",imped:"\u01b5",Implies:"\u21d2",incare:"\u2105",in:"\u2208",infin:"\u221e",infintie:"\u29dd",inodot:"\u0131",intcal:"\u22ba",int:"\u222b",Int:"\u222c",integers:"\u2124",Integral:"\u222b",intercal:"\u22ba",Intersection:"\u22c2",intlarhk:"\u2a17",intprod:"\u2a3c",InvisibleComma:"\u2063",InvisibleTimes:"\u2062",IOcy:"\u0401",iocy:"\u0451",Iogon:"\u012e",iogon:"\u012f",Iopf:"\ud835\udd40",iopf:"\ud835\udd5a",Iota:"\u0399",iota:"\u03b9",iprod:"\u2a3c",iquest:"\xbf",iscr:"\ud835\udcbe",Iscr:"\u2110",isin:"\u2208",isindot:"\u22f5",isinE:"\u22f9",isins:"\u22f4",isinsv:"\u22f3",isinv:"\u2208",it:"\u2062",Itilde:"\u0128",itilde:"\u0129",Iukcy:"\u0406",iukcy:"\u0456",Iuml:"\xcf",iuml:"\xef",Jcirc:"\u0134",jcirc:"\u0135",Jcy:"\u0419",jcy:"\u0439",Jfr:"\ud835\udd0d",jfr:"\ud835\udd27",jmath:"\u0237",Jopf:"\ud835\udd41",
jopf:"\ud835\udd5b",Jscr:"\ud835\udca5",jscr:"\ud835\udcbf",Jsercy:"\u0408",jsercy:"\u0458",Jukcy:"\u0404",jukcy:"\u0454",Kappa:"\u039a",kappa:"\u03ba",kappav:"\u03f0",Kcedil:"\u0136",kcedil:"\u0137",Kcy:"\u041a",kcy:"\u043a",Kfr:"\ud835\udd0e",kfr:"\ud835\udd28",kgreen:"\u0138",KHcy:"\u0425",khcy:"\u0445",KJcy:"\u040c",kjcy:"\u045c",Kopf:"\ud835\udd42",kopf:"\ud835\udd5c",Kscr:"\ud835\udca6",kscr:"\ud835\udcc0",lAarr:"\u21da",Lacute:"\u0139",lacute:"\u013a",laemptyv:"\u29b4",lagran:"\u2112",Lambda:"\u039b",lambda:"\u03bb",lang:"\u27e8",Lang:"\u27ea",langd:"\u2991",langle:"\u27e8",lap:"\u2a85",Laplacetrf:"\u2112",laquo:"\xab",larrb:"\u21e4",larrbfs:"\u291f",larr:"\u2190",Larr:"\u219e",lArr:"\u21d0",larrfs:"\u291d",larrhk:"\u21a9",larrlp:"\u21ab",larrpl:"\u2939",larrsim:"\u2973",larrtl:"\u21a2",latail:"\u2919",lAtail:"\u291b",lat:"\u2aab",late:"\u2aad",lates:"\u2aad\ufe00",lbarr:"\u290c",lBarr:"\u290e",lbbrk:"\u2772",lbrace:"{",lbrack:"[",lbrke:"\u298b",lbrksld:"\u298f",lbrkslu:"\u298d",Lcaron:"\u013d",lcaron:"\u013e",Lcedil:"\u013b",lcedil:"\u013c",lceil:"\u2308",lcub:"{",Lcy:"\u041b",lcy:"\u043b",ldca:"\u2936",ldquo:"\u201c",ldquor:"\u201e",ldrdhar:"\u2967",ldrushar:"\u294b",ldsh:"\u21b2",le:"\u2264",lE:"\u2266",LeftAngleBracket:"\u27e8",LeftArrowBar:"\u21e4",leftarrow:"\u2190",LeftArrow:"\u2190",Leftarrow:"\u21d0",LeftArrowRightArrow:"\u21c6",leftarrowtail:"\u21a2",LeftCeiling:"\u2308",LeftDoubleBracket:"\u27e6",LeftDownTeeVector:"\u2961",LeftDownVectorBar:"\u2959",LeftDownVector:"\u21c3",LeftFloor:"\u230a",leftharpoondown:"\u21bd",leftharpoonup:"\u21bc",leftleftarrows:"\u21c7",leftrightarrow:"\u2194",LeftRightArrow:"\u2194",Leftrightarrow:"\u21d4",leftrightarrows:"\u21c6",leftrightharpoons:"\u21cb",leftrightsquigarrow:"\u21ad",LeftRightVector:"\u294e",LeftTeeArrow:"\u21a4",LeftTee:"\u22a3",LeftTeeVector:"\u295a",leftthreetimes:"\u22cb",LeftTriangleBar:"\u29cf",LeftTriangle:"\u22b2",LeftTriangleEqual:"\u22b4",LeftUpDownVector:"\u2951",LeftUpTeeVector:"\u2960",LeftUpVectorBar:"\u2958",LeftUpVector:"\u21bf",LeftVectorBar:"\u2952",LeftVector:"\u21bc",lEg:"\u2a8b",leg:"\u22da",leq:"\u2264",leqq:"\u2266",leqslant:"\u2a7d",lescc:"\u2aa8",les:"\u2a7d",lesdot:"\u2a7f",lesdoto:"\u2a81",lesdotor:"\u2a83",lesg:"\u22da\ufe00",lesges:"\u2a93",lessapprox:"\u2a85",lessdot:"\u22d6",lesseqgtr:"\u22da",lesseqqgtr:"\u2a8b",LessEqualGreater:"\u22da",LessFullEqual:"\u2266",LessGreater:"\u2276",lessgtr:"\u2276",LessLess:"\u2aa1",lesssim:"\u2272",LessSlantEqual:"\u2a7d",LessTilde:"\u2272",lfisht:"\u297c",lfloor:"\u230a",Lfr:"\ud835\udd0f",lfr:"\ud835\udd29",lg:"\u2276",lgE:"\u2a91",lHar:"\u2962",lhard:"\u21bd",lharu:"\u21bc",lharul:"\u296a",lhblk:"\u2584",LJcy:"\u0409",ljcy:"\u0459",llarr:"\u21c7",ll:"\u226a",Ll:"\u22d8",llcorner:"\u231e",Lleftarrow:"\u21da",llhard:"\u296b",lltri:"\u25fa",Lmidot:"\u013f",lmidot:"\u0140",lmoustache:"\u23b0",lmoust:"\u23b0",lnap:"\u2a89",lnapprox:"\u2a89",lne:"\u2a87",lnE:"\u2268",lneq:"\u2a87",lneqq:"\u2268",lnsim:"\u22e6",loang:"\u27ec",loarr:"\u21fd",lobrk:"\u27e6",longleftarrow:"\u27f5",LongLeftArrow:"\u27f5",Longleftarrow:"\u27f8",longleftrightarrow:"\u27f7",LongLeftRightArrow:"\u27f7",Longleftrightarrow:"\u27fa",longmapsto:"\u27fc",longrightarrow:"\u27f6",LongRightArrow:"\u27f6",Longrightarrow:"\u27f9",looparrowleft:"\u21ab",looparrowright:"\u21ac",lopar:"\u2985",Lopf:"\ud835\udd43",lopf:"\ud835\udd5d",loplus:"\u2a2d",lotimes:"\u2a34",lowast:"\u2217",lowbar:"_",LowerLeftArrow:"\u2199",LowerRightArrow:"\u2198",loz:"\u25ca",lozenge:"\u25ca",lozf:"\u29eb",lpar:"(",lparlt:"\u2993",lrarr:"\u21c6",lrcorner:"\u231f",lrhar:"\u21cb",lrhard:"\u296d",lrm:"\u200e",lrtri:"\u22bf",lsaquo:"\u2039",lscr:"\ud835\udcc1",Lscr:"\u2112",lsh:"\u21b0",Lsh:"\u21b0",lsim:"\u2272",lsime:"\u2a8d",lsimg:"\u2a8f",lsqb:"[",lsquo:"\u2018",lsquor:"\u201a",Lstrok:"\u0141",lstrok:"\u0142",ltcc:"\u2aa6",ltcir:"\u2a79",lt:"<",LT:"<",Lt:"\u226a",ltdot:"\u22d6",lthree:"\u22cb",ltimes:"\u22c9",ltlarr:"\u2976",ltquest:"\u2a7b",ltri:"\u25c3",ltrie:"\u22b4",ltrif:"\u25c2",ltrPar:"\u2996",lurdshar:"\u294a",luruhar:"\u2966",lvertneqq:"\u2268\ufe00",lvnE:"\u2268\ufe00",macr:"\xaf",male:"\u2642",malt:"\u2720",maltese:"\u2720",Map:"\u2905",map:"\u21a6",mapsto:"\u21a6",mapstodown:"\u21a7",mapstoleft:"\u21a4",mapstoup:"\u21a5",marker:"\u25ae",mcomma:"\u2a29",Mcy:"\u041c",mcy:"\u043c",mdash:"\u2014",mDDot:"\u223a",measuredangle:"\u2221",MediumSpace:"\u205f",Mellintrf:"\u2133",Mfr:"\ud835\udd10",mfr:"\ud835\udd2a",mho:"\u2127",micro:"\xb5",midast:"*",midcir:"\u2af0",mid:"\u2223",middot:"\xb7",minusb:"\u229f",minus:"\u2212",minusd:"\u2238",minusdu:"\u2a2a",MinusPlus:"\u2213",mlcp:"\u2adb",mldr:"\u2026",mnplus:"\u2213",models:"\u22a7",Mopf:"\ud835\udd44",mopf:"\ud835\udd5e",mp:"\u2213",mscr:"\ud835\udcc2",Mscr:"\u2133",mstpos:"\u223e",Mu:"\u039c",mu:"\u03bc",multimap:"\u22b8",mumap:"\u22b8",nabla:"\u2207",Nacute:"\u0143",nacute:"\u0144",nang:"\u2220\u20d2",nap:"\u2249",napE:"\u2a70\u0338",napid:"\u224b\u0338",napos:"\u0149",napprox:"\u2249",natural:"\u266e",naturals:"\u2115",natur:"\u266e",nbsp:"\xa0",nbump:"\u224e\u0338",nbumpe:"\u224f\u0338",ncap:"\u2a43",Ncaron:"\u0147",ncaron:"\u0148",Ncedil:"\u0145",ncedil:"\u0146",ncong:"\u2247",ncongdot:"\u2a6d\u0338",ncup:"\u2a42",Ncy:"\u041d",ncy:"\u043d",ndash:"\u2013",nearhk:"\u2924",nearr:"\u2197",neArr:"\u21d7",nearrow:"\u2197",ne:"\u2260",nedot:"\u2250\u0338",NegativeMediumSpace:"\u200b",NegativeThickSpace:"\u200b",NegativeThinSpace:"\u200b",NegativeVeryThinSpace:"\u200b",nequiv:"\u2262",nesear:"\u2928",nesim:"\u2242\u0338",NestedGreaterGreater:"\u226b",NestedLessLess:"\u226a",NewLine:"\n",nexist:"\u2204",nexists:"\u2204",Nfr:"\ud835\udd11",nfr:"\ud835\udd2b",ngE:"\u2267\u0338",nge:"\u2271",ngeq:"\u2271",ngeqq:"\u2267\u0338",ngeqslant:"\u2a7e\u0338",nges:"\u2a7e\u0338",nGg:"\u22d9\u0338",ngsim:"\u2275",nGt:"\u226b\u20d2",ngt:"\u226f",ngtr:"\u226f",nGtv:"\u226b\u0338",nharr:"\u21ae",nhArr:"\u21ce",nhpar:"\u2af2",ni:"\u220b",nis:"\u22fc",nisd:"\u22fa",niv:"\u220b",NJcy:"\u040a",njcy:"\u045a",nlarr:"\u219a",nlArr:"\u21cd",nldr:"\u2025",nlE:"\u2266\u0338",nle:"\u2270",nleftarrow:"\u219a",nLeftarrow:"\u21cd",nleftrightarrow:"\u21ae",nLeftrightarrow:"\u21ce",nleq:"\u2270",nleqq:"\u2266\u0338",nleqslant:"\u2a7d\u0338",nles:"\u2a7d\u0338",nless:"\u226e",nLl:"\u22d8\u0338",nlsim:"\u2274",nLt:"\u226a\u20d2",nlt:"\u226e",nltri:"\u22ea",nltrie:"\u22ec",nLtv:"\u226a\u0338",nmid:"\u2224",NoBreak:"\u2060",NonBreakingSpace:"\xa0",nopf:"\ud835\udd5f",Nopf:"\u2115",Not:"\u2aec",not:"\xac",NotCongruent:"\u2262",NotCupCap:"\u226d",NotDoubleVerticalBar:"\u2226",NotElement:"\u2209",NotEqual:"\u2260",NotEqualTilde:"\u2242\u0338",NotExists:"\u2204",NotGreater:"\u226f",NotGreaterEqual:"\u2271",NotGreaterFullEqual:"\u2267\u0338",NotGreaterGreater:"\u226b\u0338",NotGreaterLess:"\u2279",NotGreaterSlantEqual:"\u2a7e\u0338",NotGreaterTilde:"\u2275",NotHumpDownHump:"\u224e\u0338",NotHumpEqual:"\u224f\u0338",notin:"\u2209",notindot:"\u22f5\u0338",notinE:"\u22f9\u0338",notinva:"\u2209",notinvb:"\u22f7",notinvc:"\u22f6",NotLeftTriangleBar:"\u29cf\u0338",NotLeftTriangle:"\u22ea",NotLeftTriangleEqual:"\u22ec",NotLess:"\u226e",NotLessEqual:"\u2270",NotLessGreater:"\u2278",NotLessLess:"\u226a\u0338",NotLessSlantEqual:"\u2a7d\u0338",NotLessTilde:"\u2274",NotNestedGreaterGreater:"\u2aa2\u0338",NotNestedLessLess:"\u2aa1\u0338",notni:"\u220c",notniva:"\u220c",notnivb:"\u22fe",notnivc:"\u22fd",NotPrecedes:"\u2280",NotPrecedesEqual:"\u2aaf\u0338",NotPrecedesSlantEqual:"\u22e0",NotReverseElement:"\u220c",NotRightTriangleBar:"\u29d0\u0338",NotRightTriangle:"\u22eb",NotRightTriangleEqual:"\u22ed",NotSquareSubset:"\u228f\u0338",NotSquareSubsetEqual:"\u22e2",NotSquareSuperset:"\u2290\u0338",NotSquareSupersetEqual:"\u22e3",NotSubset:"\u2282\u20d2",NotSubsetEqual:"\u2288",NotSucceeds:"\u2281",NotSucceedsEqual:"\u2ab0\u0338",NotSucceedsSlantEqual:"\u22e1",NotSucceedsTilde:"\u227f\u0338",NotSuperset:"\u2283\u20d2",NotSupersetEqual:"\u2289",NotTilde:"\u2241",NotTildeEqual:"\u2244",NotTildeFullEqual:"\u2247",NotTildeTilde:"\u2249",NotVerticalBar:"\u2224",nparallel:"\u2226",npar:"\u2226",nparsl:"\u2afd\u20e5",npart:"\u2202\u0338",npolint:"\u2a14",npr:"\u2280",nprcue:"\u22e0",nprec:"\u2280",npreceq:"\u2aaf\u0338",npre:"\u2aaf\u0338",nrarrc:"\u2933\u0338",nrarr:"\u219b",nrArr:"\u21cf",nrarrw:"\u219d\u0338",nrightarrow:"\u219b",nRightarrow:"\u21cf",nrtri:"\u22eb",nrtrie:"\u22ed",nsc:"\u2281",nsccue:"\u22e1",nsce:"\u2ab0\u0338",Nscr:"\ud835\udca9",nscr:"\ud835\udcc3",nshortmid:"\u2224",nshortparallel:"\u2226",nsim:"\u2241",nsime:"\u2244",nsimeq:"\u2244",nsmid:"\u2224",nspar:"\u2226",nsqsube:"\u22e2",nsqsupe:"\u22e3",nsub:"\u2284",nsubE:"\u2ac5\u0338",nsube:"\u2288",nsubset:"\u2282\u20d2",nsubseteq:"\u2288",nsubseteqq:"\u2ac5\u0338",nsucc:"\u2281",nsucceq:"\u2ab0\u0338",nsup:"\u2285",nsupE:"\u2ac6\u0338",nsupe:"\u2289",nsupset:"\u2283\u20d2",nsupseteq:"\u2289",nsupseteqq:"\u2ac6\u0338",ntgl:"\u2279",Ntilde:"\xd1",ntilde:"\xf1",ntlg:"\u2278",ntriangleleft:"\u22ea",ntrianglelefteq:"\u22ec",ntriangleright:"\u22eb",ntrianglerighteq:"\u22ed",Nu:"\u039d",nu:"\u03bd",num:"#",numero:"\u2116",numsp:"\u2007",nvap:"\u224d\u20d2",nvdash:"\u22ac",nvDash:"\u22ad",nVdash:"\u22ae",nVDash:"\u22af",nvge:"\u2265\u20d2",nvgt:">\u20d2",nvHarr:"\u2904",nvinfin:"\u29de",nvlArr:"\u2902",nvle:"\u2264\u20d2",nvlt:"<\u20d2",nvltrie:"\u22b4\u20d2",nvrArr:"\u2903",nvrtrie:"\u22b5\u20d2",nvsim:"\u223c\u20d2",nwarhk:"\u2923",nwarr:"\u2196",nwArr:"\u21d6",nwarrow:"\u2196",nwnear:"\u2927",Oacute:"\xd3",oacute:"\xf3",oast:"\u229b",Ocirc:"\xd4",ocirc:"\xf4",ocir:"\u229a",Ocy:"\u041e",ocy:"\u043e",odash:"\u229d",Odblac:"\u0150",odblac:"\u0151",odiv:"\u2a38",odot:"\u2299",odsold:"\u29bc",OElig:"\u0152",oelig:"\u0153",ofcir:"\u29bf",Ofr:"\ud835\udd12",ofr:"\ud835\udd2c",ogon:"\u02db",Ograve:"\xd2",ograve:"\xf2",ogt:"\u29c1",ohbar:"\u29b5",ohm:"\u03a9",oint:"\u222e",olarr:"\u21ba",olcir:"\u29be",olcross:"\u29bb",oline:"\u203e",olt:"\u29c0",Omacr:"\u014c",omacr:"\u014d",Omega:"\u03a9",omega:"\u03c9",Omicron:"\u039f",omicron:"\u03bf",omid:"\u29b6",ominus:"\u2296",Oopf:"\ud835\udd46",oopf:"\ud835\udd60",opar:"\u29b7",OpenCurlyDoubleQuote:"\u201c",OpenCurlyQuote:"\u2018",operp:"\u29b9",oplus:"\u2295",orarr:"\u21bb",Or:"\u2a54",or:"\u2228",ord:"\u2a5d",order:"\u2134",orderof:"\u2134",ordf:"\xaa",ordm:"\xba",origof:"\u22b6",oror:"\u2a56",orslope:"\u2a57",orv:"\u2a5b",oS:"\u24c8",Oscr:"\ud835\udcaa",oscr:"\u2134",Oslash:"\xd8",oslash:"\xf8",osol:"\u2298",Otilde:"\xd5",otilde:"\xf5",otimesas:"\u2a36",Otimes:"\u2a37",otimes:"\u2297",Ouml:"\xd6",ouml:"\xf6",ovbar:"\u233d",OverBar:"\u203e",OverBrace:"\u23de",OverBracket:"\u23b4",OverParenthesis:"\u23dc",para:"\xb6",parallel:"\u2225",par:"\u2225",parsim:"\u2af3",parsl:"\u2afd",part:"\u2202",PartialD:"\u2202",Pcy:"\u041f",pcy:"\u043f",percnt:"%",period:".",permil:"\u2030",perp:"\u22a5",pertenk:"\u2031",Pfr:"\ud835\udd13",pfr:"\ud835\udd2d",Phi:"\u03a6",phi:"\u03c6",phiv:"\u03d5",phmmat:"\u2133",phone:"\u260e",Pi:"\u03a0",pi:"\u03c0",pitchfork:"\u22d4",piv:"\u03d6",planck:"\u210f",planckh:"\u210e",plankv:"\u210f",plusacir:"\u2a23",plusb:"\u229e",pluscir:"\u2a22",plus:"+",plusdo:"\u2214",plusdu:"\u2a25",pluse:"\u2a72",PlusMinus:"\xb1",plusmn:"\xb1",plussim:"\u2a26",plustwo:"\u2a27",pm:"\xb1",Poincareplane:"\u210c",pointint:"\u2a15",popf:"\ud835\udd61",Popf:"\u2119",pound:"\xa3",prap:"\u2ab7",Pr:"\u2abb",pr:"\u227a",prcue:"\u227c",precapprox:"\u2ab7",prec:"\u227a",preccurlyeq:"\u227c",Precedes:"\u227a",PrecedesEqual:"\u2aaf",PrecedesSlantEqual:"\u227c",PrecedesTilde:"\u227e",preceq:"\u2aaf",precnapprox:"\u2ab9",precneqq:"\u2ab5",precnsim:"\u22e8",pre:"\u2aaf",prE:"\u2ab3",precsim:"\u227e",prime:"\u2032",Prime:"\u2033",primes:"\u2119",prnap:"\u2ab9",prnE:"\u2ab5",prnsim:"\u22e8",prod:"\u220f",Product:"\u220f",profalar:"\u232e",profline:"\u2312",profsurf:"\u2313",prop:"\u221d",Proportional:"\u221d",Proportion:"\u2237",propto:"\u221d",prsim:"\u227e",prurel:"\u22b0",Pscr:"\ud835\udcab",pscr:"\ud835\udcc5",Psi:"\u03a8",psi:"\u03c8",puncsp:"\u2008",Qfr:"\ud835\udd14",qfr:"\ud835\udd2e",qint:"\u2a0c",qopf:"\ud835\udd62",Qopf:"\u211a",qprime:"\u2057",Qscr:"\ud835\udcac",qscr:"\ud835\udcc6",quaternions:"\u210d",quatint:"\u2a16",quest:"?",questeq:"\u225f",quot:'"',QUOT:'"',rAarr:"\u21db",race:"\u223d\u0331",Racute:"\u0154",racute:"\u0155",radic:"\u221a",raemptyv:"\u29b3",rang:"\u27e9",Rang:"\u27eb",rangd:"\u2992",range:"\u29a5",rangle:"\u27e9",raquo:"\xbb",rarrap:"\u2975",rarrb:"\u21e5",rarrbfs:"\u2920",rarrc:"\u2933",rarr:"\u2192",Rarr:"\u21a0",rArr:"\u21d2",rarrfs:"\u291e",rarrhk:"\u21aa",rarrlp:"\u21ac",rarrpl:"\u2945",rarrsim:"\u2974",Rarrtl:"\u2916",rarrtl:"\u21a3",rarrw:"\u219d",ratail:"\u291a",rAtail:"\u291c",ratio:"\u2236",rationals:"\u211a",rbarr:"\u290d",rBarr:"\u290f",RBarr:"\u2910",rbbrk:"\u2773",rbrace:"}",rbrack:"]",rbrke:"\u298c",rbrksld:"\u298e",rbrkslu:"\u2990",Rcaron:"\u0158",rcaron:"\u0159",Rcedil:"\u0156",rcedil:"\u0157",rceil:"\u2309",rcub:"}",Rcy:"\u0420",rcy:"\u0440",rdca:"\u2937",rdldhar:"\u2969",rdquo:"\u201d",rdquor:"\u201d",rdsh:"\u21b3",real:"\u211c",realine:"\u211b",realpart:"\u211c",reals:"\u211d",Re:"\u211c",rect:"\u25ad",reg:"\xae",REG:"\xae",ReverseElement:"\u220b",ReverseEquilibrium:"\u21cb",ReverseUpEquilibrium:"\u296f",rfisht:"\u297d",rfloor:"\u230b",rfr:"\ud835\udd2f",Rfr:"\u211c",rHar:"\u2964",rhard:"\u21c1",rharu:"\u21c0",rharul:"\u296c",Rho:"\u03a1",rho:"\u03c1",rhov:"\u03f1",RightAngleBracket:"\u27e9",RightArrowBar:"\u21e5",rightarrow:"\u2192",RightArrow:"\u2192",Rightarrow:"\u21d2",RightArrowLeftArrow:"\u21c4",rightarrowtail:"\u21a3",RightCeiling:"\u2309",RightDoubleBracket:"\u27e7",RightDownTeeVector:"\u295d",RightDownVectorBar:"\u2955",RightDownVector:"\u21c2",RightFloor:"\u230b",rightharpoondown:"\u21c1",rightharpoonup:"\u21c0",rightleftarrows:"\u21c4",rightleftharpoons:"\u21cc",rightrightarrows:"\u21c9",rightsquigarrow:"\u219d",RightTeeArrow:"\u21a6",RightTee:"\u22a2",RightTeeVector:"\u295b",rightthreetimes:"\u22cc",RightTriangleBar:"\u29d0",RightTriangle:"\u22b3",RightTriangleEqual:"\u22b5",RightUpDownVector:"\u294f",RightUpTeeVector:"\u295c",RightUpVectorBar:"\u2954",RightUpVector:"\u21be",RightVectorBar:"\u2953",RightVector:"\u21c0",ring:"\u02da",risingdotseq:"\u2253",rlarr:"\u21c4",rlhar:"\u21cc",rlm:"\u200f",rmoustache:"\u23b1",rmoust:"\u23b1",rnmid:"\u2aee",roang:"\u27ed",roarr:"\u21fe",robrk:"\u27e7",ropar:"\u2986",ropf:"\ud835\udd63",Ropf:"\u211d",roplus:"\u2a2e",rotimes:"\u2a35",RoundImplies:"\u2970",rpar:")",rpargt:"\u2994",rppolint:"\u2a12",rrarr:"\u21c9",Rrightarrow:"\u21db",rsaquo:"\u203a",rscr:"\ud835\udcc7",Rscr:"\u211b",rsh:"\u21b1",Rsh:"\u21b1",rsqb:"]",rsquo:"\u2019",rsquor:"\u2019",rthree:"\u22cc",rtimes:"\u22ca",rtri:"\u25b9",rtrie:"\u22b5",rtrif:"\u25b8",rtriltri:"\u29ce",RuleDelayed:"\u29f4",ruluhar:"\u2968",rx:"\u211e",Sacute:"\u015a",sacute:"\u015b",sbquo:"\u201a",scap:"\u2ab8",Scaron:"\u0160",scaron:"\u0161",Sc:"\u2abc",sc:"\u227b",sccue:"\u227d",sce:"\u2ab0",scE:"\u2ab4",Scedil:"\u015e",scedil:"\u015f",Scirc:"\u015c",scirc:"\u015d",scnap:"\u2aba",scnE:"\u2ab6",scnsim:"\u22e9",scpolint:"\u2a13",scsim:"\u227f",Scy:"\u0421",scy:"\u0441",sdotb:"\u22a1",sdot:"\u22c5",sdote:"\u2a66",searhk:"\u2925",searr:"\u2198",seArr:"\u21d8",searrow:"\u2198",sect:"\xa7",semi:";",seswar:"\u2929",setminus:"\u2216",setmn:"\u2216",sext:"\u2736",Sfr:"\ud835\udd16",sfr:"\ud835\udd30",sfrown:"\u2322",sharp:"\u266f",SHCHcy:"\u0429",shchcy:"\u0449",SHcy:"\u0428",shcy:"\u0448",ShortDownArrow:"\u2193",ShortLeftArrow:"\u2190",shortmid:"\u2223",shortparallel:"\u2225",ShortRightArrow:"\u2192",ShortUpArrow:"\u2191",shy:"\xad",Sigma:"\u03a3",sigma:"\u03c3",sigmaf:"\u03c2",sigmav:"\u03c2",sim:"\u223c",simdot:"\u2a6a",sime:"\u2243",simeq:"\u2243",simg:"\u2a9e",simgE:"\u2aa0",siml:"\u2a9d",simlE:"\u2a9f",simne:"\u2246",simplus:"\u2a24",simrarr:"\u2972",slarr:"\u2190",SmallCircle:"\u2218",smallsetminus:"\u2216",smashp:"\u2a33",smeparsl:"\u29e4",smid:"\u2223",smile:"\u2323",smt:"\u2aaa",smte:"\u2aac",smtes:"\u2aac\ufe00",SOFTcy:"\u042c",softcy:"\u044c",solbar:"\u233f",solb:"\u29c4",sol:"/",Sopf:"\ud835\udd4a",sopf:"\ud835\udd64",spades:"\u2660",spadesuit:"\u2660",spar:"\u2225",sqcap:"\u2293",sqcaps:"\u2293\ufe00",sqcup:"\u2294",sqcups:"\u2294\ufe00",Sqrt:"\u221a",sqsub:"\u228f",sqsube:"\u2291",sqsubset:"\u228f",sqsubseteq:"\u2291",sqsup:"\u2290",sqsupe:"\u2292",sqsupset:"\u2290",sqsupseteq:"\u2292",square:"\u25a1",Square:"\u25a1",SquareIntersection:"\u2293",SquareSubset:"\u228f",SquareSubsetEqual:"\u2291",SquareSuperset:"\u2290",SquareSupersetEqual:"\u2292",SquareUnion:"\u2294",squarf:"\u25aa",squ:"\u25a1",squf:"\u25aa",srarr:"\u2192",Sscr:"\ud835\udcae",sscr:"\ud835\udcc8",ssetmn:"\u2216",ssmile:"\u2323",sstarf:"\u22c6",Star:"\u22c6",star:"\u2606",starf:"\u2605",straightepsilon:"\u03f5",straightphi:"\u03d5",strns:"\xaf",sub:"\u2282",Sub:"\u22d0",subdot:"\u2abd",subE:"\u2ac5",sube:"\u2286",subedot:"\u2ac3",submult:"\u2ac1",subnE:"\u2acb",subne:"\u228a",subplus:"\u2abf",subrarr:"\u2979",subset:"\u2282",Subset:"\u22d0",subseteq:"\u2286",subseteqq:"\u2ac5",SubsetEqual:"\u2286",subsetneq:"\u228a",subsetneqq:"\u2acb",subsim:"\u2ac7",subsub:"\u2ad5",subsup:"\u2ad3",succapprox:"\u2ab8",succ:"\u227b",succcurlyeq:"\u227d",Succeeds:"\u227b",SucceedsEqual:"\u2ab0",SucceedsSlantEqual:"\u227d",SucceedsTilde:"\u227f",succeq:"\u2ab0",succnapprox:"\u2aba",succneqq:"\u2ab6",succnsim:"\u22e9",succsim:"\u227f",SuchThat:"\u220b",sum:"\u2211",Sum:"\u2211",sung:"\u266a",sup1:"\xb9",sup2:"\xb2",sup3:"\xb3",sup:"\u2283",Sup:"\u22d1",supdot:"\u2abe",supdsub:"\u2ad8",supE:"\u2ac6",supe:"\u2287",supedot:"\u2ac4",Superset:"\u2283",SupersetEqual:"\u2287",suphsol:"\u27c9",suphsub:"\u2ad7",suplarr:"\u297b",supmult:"\u2ac2",supnE:"\u2acc",supne:"\u228b",supplus:"\u2ac0",supset:"\u2283",Supset:"\u22d1",supseteq:"\u2287",supseteqq:"\u2ac6",supsetneq:"\u228b",supsetneqq:"\u2acc",supsim:"\u2ac8",supsub:"\u2ad4",supsup:"\u2ad6",swarhk:"\u2926",swarr:"\u2199",swArr:"\u21d9",swarrow:"\u2199",swnwar:"\u292a",szlig:"\xdf",Tab:"\t",target:"\u2316",Tau:"\u03a4",tau:"\u03c4",tbrk:"\u23b4",Tcaron:"\u0164",tcaron:"\u0165",Tcedil:"\u0162",tcedil:"\u0163",Tcy:"\u0422",tcy:"\u0442",tdot:"\u20db",telrec:"\u2315",Tfr:"\ud835\udd17",tfr:"\ud835\udd31",there4:"\u2234",therefore:"\u2234",Therefore:"\u2234",Theta:"\u0398",theta:"\u03b8",thetasym:"\u03d1",thetav:"\u03d1",thickapprox:"\u2248",thicksim:"\u223c",ThickSpace:"\u205f\u200a",ThinSpace:"\u2009",thinsp:"\u2009",thkap:"\u2248",thksim:"\u223c",THORN:"\xde",thorn:"\xfe",tilde:"\u02dc",Tilde:"\u223c",TildeEqual:"\u2243",TildeFullEqual:"\u2245",TildeTilde:"\u2248",timesbar:"\u2a31",timesb:"\u22a0",times:"\xd7",timesd:"\u2a30",tint:"\u222d",toea:"\u2928",topbot:"\u2336",topcir:"\u2af1",top:"\u22a4",Topf:"\ud835\udd4b",topf:"\ud835\udd65",topfork:"\u2ada",tosa:"\u2929",tprime:"\u2034",trade:"\u2122",TRADE:"\u2122",triangle:"\u25b5",triangledown:"\u25bf",triangleleft:"\u25c3",trianglelefteq:"\u22b4",triangleq:"\u225c",triangleright:"\u25b9",trianglerighteq:"\u22b5",tridot:"\u25ec",trie:"\u225c",triminus:"\u2a3a",TripleDot:"\u20db",triplus:"\u2a39",trisb:"\u29cd",tritime:"\u2a3b",trpezium:"\u23e2",Tscr:"\ud835\udcaf",tscr:"\ud835\udcc9",TScy:"\u0426",tscy:"\u0446",TSHcy:"\u040b",tshcy:"\u045b",Tstrok:"\u0166",tstrok:"\u0167",twixt:"\u226c",twoheadleftarrow:"\u219e",twoheadrightarrow:"\u21a0",Uacute:"\xda",uacute:"\xfa",uarr:"\u2191",Uarr:"\u219f",uArr:"\u21d1",Uarrocir:"\u2949",Ubrcy:"\u040e",ubrcy:"\u045e",Ubreve:"\u016c",ubreve:"\u016d",Ucirc:"\xdb",ucirc:"\xfb",Ucy:"\u0423",ucy:"\u0443",udarr:"\u21c5",Udblac:"\u0170",udblac:"\u0171",udhar:"\u296e",ufisht:"\u297e",Ufr:"\ud835\udd18",ufr:"\ud835\udd32",Ugrave:"\xd9",ugrave:"\xf9",uHar:"\u2963",uharl:"\u21bf",uharr:"\u21be",uhblk:"\u2580",ulcorn:"\u231c",ulcorner:"\u231c",ulcrop:"\u230f",ultri:"\u25f8",Umacr:"\u016a",umacr:"\u016b",uml:"\xa8",UnderBar:"_",UnderBrace:"\u23df",UnderBracket:"\u23b5",UnderParenthesis:"\u23dd",Union:"\u22c3",UnionPlus:"\u228e",Uogon:"\u0172",uogon:"\u0173",Uopf:"\ud835\udd4c",uopf:"\ud835\udd66",UpArrowBar:"\u2912",uparrow:"\u2191",UpArrow:"\u2191",Uparrow:"\u21d1",UpArrowDownArrow:"\u21c5",updownarrow:"\u2195",UpDownArrow:"\u2195",Updownarrow:"\u21d5",UpEquilibrium:"\u296e",upharpoonleft:"\u21bf",upharpoonright:"\u21be",uplus:"\u228e",UpperLeftArrow:"\u2196",UpperRightArrow:"\u2197",upsi:"\u03c5",Upsi:"\u03d2",upsih:"\u03d2",Upsilon:"\u03a5",upsilon:"\u03c5",UpTeeArrow:"\u21a5",UpTee:"\u22a5",upuparrows:"\u21c8",urcorn:"\u231d",urcorner:"\u231d",urcrop:"\u230e",Uring:"\u016e",uring:"\u016f",urtri:"\u25f9",Uscr:"\ud835\udcb0",uscr:"\ud835\udcca",utdot:"\u22f0",Utilde:"\u0168",utilde:"\u0169",utri:"\u25b5",utrif:"\u25b4",uuarr:"\u21c8",Uuml:"\xdc",uuml:"\xfc",uwangle:"\u29a7",vangrt:"\u299c",varepsilon:"\u03f5",varkappa:"\u03f0",varnothing:"\u2205",varphi:"\u03d5",varpi:"\u03d6",varpropto:"\u221d",varr:"\u2195",vArr:"\u21d5",varrho:"\u03f1",varsigma:"\u03c2",varsubsetneq:"\u228a\ufe00",varsubsetneqq:"\u2acb\ufe00",varsupsetneq:"\u228b\ufe00",varsupsetneqq:"\u2acc\ufe00",vartheta:"\u03d1",vartriangleleft:"\u22b2",vartriangleright:"\u22b3",vBar:"\u2ae8",Vbar:"\u2aeb",vBarv:"\u2ae9",Vcy:"\u0412",vcy:"\u0432",vdash:"\u22a2",vDash:"\u22a8",Vdash:"\u22a9",VDash:"\u22ab",Vdashl:"\u2ae6",veebar:"\u22bb",vee:"\u2228",Vee:"\u22c1",veeeq:"\u225a",vellip:"\u22ee",verbar:"|",Verbar:"\u2016",vert:"|",Vert:"\u2016",VerticalBar:"\u2223",VerticalLine:"|",VerticalSeparator:"\u2758",VerticalTilde:"\u2240",VeryThinSpace:"\u200a",Vfr:"\ud835\udd19",vfr:"\ud835\udd33",vltri:"\u22b2",vnsub:"\u2282\u20d2",vnsup:"\u2283\u20d2",Vopf:"\ud835\udd4d",vopf:"\ud835\udd67",vprop:"\u221d",vrtri:"\u22b3",Vscr:"\ud835\udcb1",vscr:"\ud835\udccb",vsubnE:"\u2acb\ufe00",vsubne:"\u228a\ufe00",vsupnE:"\u2acc\ufe00",vsupne:"\u228b\ufe00",Vvdash:"\u22aa",vzigzag:"\u299a",Wcirc:"\u0174",wcirc:"\u0175",wedbar:"\u2a5f",wedge:"\u2227",Wedge:"\u22c0",wedgeq:"\u2259",weierp:"\u2118",Wfr:"\ud835\udd1a",wfr:"\ud835\udd34",Wopf:"\ud835\udd4e",wopf:"\ud835\udd68",wp:"\u2118",wr:"\u2240",wreath:"\u2240",Wscr:"\ud835\udcb2",wscr:"\ud835\udccc",xcap:"\u22c2",xcirc:"\u25ef",xcup:"\u22c3",xdtri:"\u25bd",Xfr:"\ud835\udd1b",xfr:"\ud835\udd35",xharr:"\u27f7",xhArr:"\u27fa",Xi:"\u039e",xi:"\u03be",xlarr:"\u27f5",xlArr:"\u27f8",xmap:"\u27fc",xnis:"\u22fb",xodot:"\u2a00",Xopf:"\ud835\udd4f",xopf:"\ud835\udd69",xoplus:"\u2a01",xotime:"\u2a02",xrarr:"\u27f6",xrArr:"\u27f9",Xscr:"\ud835\udcb3",xscr:"\ud835\udccd",xsqcup:"\u2a06",xuplus:"\u2a04",xutri:"\u25b3",xvee:"\u22c1",xwedge:"\u22c0",Yacute:"\xdd",yacute:"\xfd",YAcy:"\u042f",yacy:"\u044f",Ycirc:"\u0176",ycirc:"\u0177",Ycy:"\u042b",ycy:"\u044b",yen:"\xa5",Yfr:"\ud835\udd1c",yfr:"\ud835\udd36",YIcy:"\u0407",yicy:"\u0457",Yopf:"\ud835\udd50",yopf:"\ud835\udd6a",Yscr:"\ud835\udcb4",yscr:"\ud835\udcce",YUcy:"\u042e",yucy:"\u044e",yuml:"\xff",Yuml:"\u0178",Zacute:"\u0179",zacute:"\u017a",Zcaron:"\u017d",zcaron:"\u017e",Zcy:"\u0417",zcy:"\u0437",Zdot:"\u017b",zdot:"\u017c",zeetrf:"\u2128",ZeroWidthSpace:"\u200b",Zeta:"\u0396",zeta:"\u03b6",zfr:"\ud835\udd37",Zfr:"\u2128",ZHcy:"\u0416",zhcy:"\u0436",zigrarr:"\u21dd",zopf:"\ud835\udd6b",Zopf:"\u2124",Zscr:"\ud835\udcb5",zscr:"\ud835\udccf",zwj:"\u200d",zwnj:"\u200c"}},{}],53:[function(e,r,t){"use strict";function n(e){return Array.prototype.slice.call(arguments,1).forEach(function(r){r&&Object.keys(r).forEach(function(t){e[t]=r[t]})}),e}function s(e){return Object.prototype.toString.call(e)}function o(e){return"[object String]"===s(e)}function i(e){return"[object Object]"===s(e)}function a(e){return"[object RegExp]"===s(e)}function c(e){return"[object Function]"===s(e)}function l(e){return e.replace(/[.?*+^$[\]\\(){}|-]/g,"\\$&")}function u(e){return Object.keys(e||{}).reduce(function(e,r){return e||b.hasOwnProperty(r)},!1)}function p(e){e.__index__=-1,e.__text_cache__=""}function h(e){return function(r,t){var n=r.slice(t);return e.test(n)?n.match(e)[0].length:0}}function f(){return function(e,r){r.normalize(e)}}function d(r){function t(e){return e.replace("%TLDS%",s.src_tlds)}function n(e,r){throw new Error('(LinkifyIt) Invalid schema "'+e+'": '+r)}var s=r.re=e("./lib/re")(r.__opts__),u=r.__tlds__.slice();r.onCompile(),r.__tlds_replaced__||u.push("a[cdefgilmnoqrstuwxz]|b[abdefghijmnorstvwyz]|c[acdfghiklmnoruvwxyz]|d[ejkmoz]|e[cegrstu]|f[ijkmor]|g[abdefghilmnpqrstuwy]|h[kmnrtu]|i[delmnoqrst]|j[emop]|k[eghimnprwyz]|l[abcikrstuvy]|m[acdeghklmnopqrstuvwxyz]|n[acefgilopruz]|om|p[aefghklmnrstwy]|qa|r[eosuw]|s[abcdeghijklmnortuvxyz]|t[cdfghjklmnortvwz]|u[agksyz]|v[aceginu]|w[fs]|y[et]|z[amw]"),u.push(s.src_xn),s.src_tlds=u.join("|"),s.email_fuzzy=RegExp(t(s.tpl_email_fuzzy),"i"),s.link_fuzzy=RegExp(t(s.tpl_link_fuzzy),"i"),s.link_no_ip_fuzzy=RegExp(t(s.tpl_link_no_ip_fuzzy),"i"),s.host_fuzzy_test=RegExp(t(s.tpl_host_fuzzy_test),"i");var d=[];r.__compiled__={},Object.keys(r.__schemas__).forEach(function(e){var t=r.__schemas__[e];if(null!==t){var s={validate:null,link:null};return r.__compiled__[e]=s,i(t)?(a(t.validate)?s.validate=h(t.validate):c(t.validate)?s.validate=t.validate:n(e,t),void(c(t.normalize)?s.normalize=t.normalize:t.normalize?n(e,t):s.normalize=f())):o(t)?void d.push(e):void n(e,t)}}),d.forEach(function(e){r.__compiled__[r.__schemas__[e]]&&(r.__compiled__[e].validate=r.__compiled__[r.__schemas__[e]].validate,r.__compiled__[e].normalize=r.__compiled__[r.__schemas__[e]].normalize)}),r.__compiled__[""]={validate:null,normalize:f()};var m=Object.keys(r.__compiled__).filter(function(e){return e.length>0&&r.__compiled__[e]}).map(l).join("|");r.re.schema_test=RegExp("(^|(?!_)(?:[><\uff5c]|"+s.src_ZPCc+"))("+m+")","i"),r.re.schema_search=RegExp("(^|(?!_)(?:[><\uff5c]|"+s.src_ZPCc+"))("+m+")","ig"),r.re.pretest=RegExp("("+r.re.schema_test.source+")|("+r.re.host_fuzzy_test.source+")|@","i"),p(r)}function m(e,r){var t=e.__index__,n=e.__last_index__,s=e.__text_cache__.slice(t,n);this.schema=e.__schema__.toLowerCase(),this.index=t+r,this.lastIndex=n+r,this.raw=s,this.text=s,this.url=s}function _(e,r){var t=new m(e,r);return e.__compiled__[t.schema].normalize(t,e),t}function g(e,r){if(!(this instanceof g))return new g(e,r);r||u(e)&&(r=e,e={}),this.__opts__=n({},b,r),this.__index__=-1,this.__last_index__=-1,this.__schema__="",this.__text_cache__="",this.__schemas__=n({},k,e),this.__compiled__={},this.__tlds__=v,this.__tlds_replaced__=!1,this.re={},d(this)}var b={fuzzyLink:!0,fuzzyEmail:!0,fuzzyIP:!1},k={"http:":{validate:function(e,r,t){var n=e.slice(r);return t.re.http||(t.re.http=new RegExp("^\\/\\/"+t.re.src_auth+t.re.src_host_port_strict+t.re.src_path,"i")),t.re.http.test(n)?n.match(t.re.http)[0].length:0}},"https:":"http:","ftp:":"http:","//":{validate:function(e,r,t){var n=e.slice(r);return t.re.no_http||(t.re.no_http=new RegExp("^"+t.re.src_auth+"(?:localhost|(?:(?:"+t.re.src_domain+")\\.)+"+t.re.src_domain_root+")"+t.re.src_port+t.re.src_host_terminator+t.re.src_path,"i")),t.re.no_http.test(n)?r>=3&&":"===e[r-3]?0:r>=3&&"/"===e[r-3]?0:n.match(t.re.no_http)[0].length:0}},"mailto:":{validate:function(e,r,t){var n=e.slice(r);return t.re.mailto||(t.re.mailto=new RegExp("^"+t.re.src_email_name+"@"+t.re.src_host_strict,"i")),t.re.mailto.test(n)?n.match(t.re.mailto)[0].length:0}}},v="biz|com|edu|gov|net|org|pro|web|xxx|aero|asia|coop|info|museum|name|shop|\u0440\u0444".split("|");g.prototype.add=function(e,r){return this.__schemas__[e]=r,d(this),this},g.prototype.set=function(e){return this.__opts__=n(this.__opts__,e),this},g.prototype.test=function(e){if(this.__text_cache__=e,this.__index__=-1,!e.length)return!1;var r,t,n,s,o,i,a,c;if(this.re.schema_test.test(e))for(a=this.re.schema_search,a.lastIndex=0;null!==(r=a.exec(e));)if(s=this.testSchemaAt(e,r[2],a.lastIndex)){this.__schema__=r[2],this.__index__=r.index+r[1].length,this.__last_index__=r.index+r[0].length+s;break}return this.__opts__.fuzzyLink&&this.__compiled__["http:"]&&(c=e.search(this.re.host_fuzzy_test))>=0&&(this.__index__<0||c<this.__index__)&&null!==(t=e.match(this.__opts__.fuzzyIP?this.re.link_fuzzy:this.re.link_no_ip_fuzzy))&&(o=t.index+t[1].length,(this.__index__<0||o<this.__index__)&&(this.__schema__="",this.__index__=o,this.__last_index__=t.index+t[0].length)),this.__opts__.fuzzyEmail&&this.__compiled__["mailto:"]&&e.indexOf("@")>=0&&null!==(n=e.match(this.re.email_fuzzy))&&(o=n.index+n[1].length,i=n.index+n[0].length,(this.__index__<0||o<this.__index__||o===this.__index__&&i>this.__last_index__)&&(this.__schema__="mailto:",this.__index__=o,this.__last_index__=i)),this.__index__>=0},g.prototype.pretest=function(e){return this.re.pretest.test(e)},g.prototype.testSchemaAt=function(e,r,t){return this.__compiled__[r.toLowerCase()]?this.__compiled__[r.toLowerCase()].validate(e,t,this):0},g.prototype.match=function(e){var r=0,t=[];this.__index__>=0&&this.__text_cache__===e&&(t.push(_(this,r)),r=this.__last_index__);for(var n=r?e.slice(r):e;this.test(n);)t.push(_(this,r)),n=n.slice(this.__last_index__),r+=this.__last_index__;return t.length?t:null},g.prototype.tlds=function(e,r){return e=Array.isArray(e)?e:[e],r?(this.__tlds__=this.__tlds__.concat(e).sort().filter(function(e,r,t){return e!==t[r-1]}).reverse(),d(this),this):(this.__tlds__=e.slice(),this.__tlds_replaced__=!0,d(this),this)},g.prototype.normalize=function(e){e.schema||(e.url="http://"+e.url),"mailto:"!==e.schema||/^mailto:/i.test(e.url)||(e.url="mailto:"+e.url)},g.prototype.onCompile=function(){},r.exports=g},{"./lib/re":54}],54:[function(e,r,t){"use strict";r.exports=function(r){var t={};t.src_Any=e("uc.micro/properties/Any/regex").source,t.src_Cc=e("uc.micro/categories/Cc/regex").source,t.src_Z=e("uc.micro/categories/Z/regex").source,t.src_P=e("uc.micro/categories/P/regex").source,t.src_ZPCc=[t.src_Z,t.src_P,t.src_Cc].join("|"),t.src_ZCc=[t.src_Z,t.src_Cc].join("|");return t.src_pseudo_letter="(?:(?![><\uff5c]|"+t.src_ZPCc+")"+t.src_Any+")",t.src_ip4="(?:(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)",t.src_auth="(?:(?:(?!"+t.src_ZCc+"|[@/\\[\\]()]).)+@)?",t.src_port="(?::(?:6(?:[0-4]\\d{3}|5(?:[0-4]\\d{2}|5(?:[0-2]\\d|3[0-5])))|[1-5]?\\d{1,4}))?",t.src_host_terminator="(?=$|[><\uff5c]|"+t.src_ZPCc+")(?!-|_|:\\d|\\.-|\\.(?!$|"+t.src_ZPCc+"))",t.src_path="(?:[/?#](?:(?!"+t.src_ZCc+"|[><\uff5c]|[()[\\]{}.,\"'?!\\-]).|\\[(?:(?!"+t.src_ZCc+"|\\]).)*\\]|\\((?:(?!"+t.src_ZCc+"|[)]).)*\\)|\\{(?:(?!"+t.src_ZCc+'|[}]).)*\\}|\\"(?:(?!'+t.src_ZCc+'|["]).)+\\"|\\\'(?:(?!'+t.src_ZCc+"|[']).)+\\'|\\'(?="+t.src_pseudo_letter+"|[-]).|\\.{2,3}[a-zA-Z0-9%/]|\\.(?!"+t.src_ZCc+"|[.]).|"+(r&&r["---"]?"\\-(?!--(?:[^-]|$))(?:-*)|":"\\-+|")+"\\,(?!"+t.src_ZCc+").|\\!(?!"+t.src_ZCc+"|[!]).|\\?(?!"+t.src_ZCc+"|[?]).)+|\\/)?",t.src_email_name='[\\-;:&=\\+\\$,\\"\\.a-zA-Z0-9_]+',t.src_xn="xn--[a-z0-9\\-]{1,59}",t.src_domain_root="(?:"+t.src_xn+"|"+t.src_pseudo_letter+"{1,63})",t.src_domain="(?:"+t.src_xn+"|(?:"+t.src_pseudo_letter+")|(?:"+t.src_pseudo_letter+"(?:-(?!-)|"+t.src_pseudo_letter+"){0,61}"+t.src_pseudo_letter+"))",t.src_host="(?:(?:(?:(?:"+t.src_domain+")\\.)*"+t.src_domain+"))",t.tpl_host_fuzzy="(?:"+t.src_ip4+"|(?:(?:(?:"+t.src_domain+")\\.)+(?:%TLDS%)))",t.tpl_host_no_ip_fuzzy="(?:(?:(?:"+t.src_domain+")\\.)+(?:%TLDS%))",t.src_host_strict=t.src_host+t.src_host_terminator,t.tpl_host_fuzzy_strict=t.tpl_host_fuzzy+t.src_host_terminator,t.src_host_port_strict=t.src_host+t.src_port+t.src_host_terminator,t.tpl_host_port_fuzzy_strict=t.tpl_host_fuzzy+t.src_port+t.src_host_terminator,t.tpl_host_port_no_ip_fuzzy_strict=t.tpl_host_no_ip_fuzzy+t.src_port+t.src_host_terminator,t.tpl_host_fuzzy_test="localhost|www\\.|\\.\\d{1,3}\\.|(?:\\.(?:%TLDS%)(?:"+t.src_ZPCc+"|>|$))",t.tpl_email_fuzzy="(^|[><\uff5c]|\\(|"+t.src_ZCc+")("+t.src_email_name+"@"+t.tpl_host_fuzzy_strict+")",t.tpl_link_fuzzy="(^|(?![.:/\\-_@])(?:[$+<=>^`|\uff5c]|"+t.src_ZPCc+"))((?![$+<=>^`|\uff5c])"+t.tpl_host_port_fuzzy_strict+t.src_path+")",t.tpl_link_no_ip_fuzzy="(^|(?![.:/\\-_@])(?:[$+<=>^`|\uff5c]|"+t.src_ZPCc+"))((?![$+<=>^`|\uff5c])"+t.tpl_host_port_no_ip_fuzzy_strict+t.src_path+")",t}},{
"uc.micro/categories/Cc/regex":61,"uc.micro/categories/P/regex":63,"uc.micro/categories/Z/regex":64,"uc.micro/properties/Any/regex":66}],55:[function(e,r,t){"use strict";function n(e){var r,t,n=o[e];if(n)return n;for(n=o[e]=[],r=0;r<128;r++)t=String.fromCharCode(r),n.push(t);for(r=0;r<e.length;r++)t=e.charCodeAt(r),n[t]="%"+("0"+t.toString(16).toUpperCase()).slice(-2);return n}function s(e,r){var t;return"string"!=typeof r&&(r=s.defaultChars),t=n(r),e.replace(/(%[a-f0-9]{2})+/gi,function(e){var r,n,s,o,i,a,c,l="";for(r=0,n=e.length;r<n;r+=3)s=parseInt(e.slice(r+1,r+3),16),s<128?l+=t[s]:192==(224&s)&&r+3<n&&128==(192&(o=parseInt(e.slice(r+4,r+6),16)))?(c=s<<6&1984|63&o,l+=c<128?"\ufffd\ufffd":String.fromCharCode(c),r+=3):224==(240&s)&&r+6<n&&(o=parseInt(e.slice(r+4,r+6),16),i=parseInt(e.slice(r+7,r+9),16),128==(192&o)&&128==(192&i))?(c=s<<12&61440|o<<6&4032|63&i,l+=c<2048||c>=55296&&c<=57343?"\ufffd\ufffd\ufffd":String.fromCharCode(c),r+=6):240==(248&s)&&r+9<n&&(o=parseInt(e.slice(r+4,r+6),16),i=parseInt(e.slice(r+7,r+9),16),a=parseInt(e.slice(r+10,r+12),16),128==(192&o)&&128==(192&i)&&128==(192&a))?(c=s<<18&1835008|o<<12&258048|i<<6&4032|63&a,c<65536||c>1114111?l+="\ufffd\ufffd\ufffd\ufffd":(c-=65536,l+=String.fromCharCode(55296+(c>>10),56320+(1023&c))),r+=9):l+="\ufffd";return l})}var o={};s.defaultChars=";/?:@&=+$,#",s.componentChars="",r.exports=s},{}],56:[function(e,r,t){"use strict";function n(e){var r,t,n=o[e];if(n)return n;for(n=o[e]=[],r=0;r<128;r++)t=String.fromCharCode(r),/^[0-9a-z]$/i.test(t)?n.push(t):n.push("%"+("0"+r.toString(16).toUpperCase()).slice(-2));for(r=0;r<e.length;r++)n[e.charCodeAt(r)]=e[r];return n}function s(e,r,t){var o,i,a,c,l,u="";for("string"!=typeof r&&(t=r,r=s.defaultChars),void 0===t&&(t=!0),l=n(r),o=0,i=e.length;o<i;o++)if(a=e.charCodeAt(o),t&&37===a&&o+2<i&&/^[0-9a-f]{2}$/i.test(e.slice(o+1,o+3)))u+=e.slice(o,o+3),o+=2;else if(a<128)u+=l[a];else if(a>=55296&&a<=57343){if(a>=55296&&a<=56319&&o+1<i&&(c=e.charCodeAt(o+1))>=56320&&c<=57343){u+=encodeURIComponent(e[o]+e[o+1]),o++;continue}u+="%EF%BF%BD"}else u+=encodeURIComponent(e[o]);return u}var o={};s.defaultChars=";/?:@&=+$,-_.!~*'()#",s.componentChars="-_.!~*'()",r.exports=s},{}],57:[function(e,r,t){"use strict";r.exports=function(e){var r="";return r+=e.protocol||"",r+=e.slashes?"//":"",r+=e.auth?e.auth+"@":"",r+=e.hostname&&e.hostname.indexOf(":")!==-1?"["+e.hostname+"]":e.hostname||"",r+=e.port?":"+e.port:"",r+=e.pathname||"",r+=e.search||"",r+=e.hash||""}},{}],58:[function(e,r,t){"use strict";r.exports.encode=e("./encode"),r.exports.decode=e("./decode"),r.exports.format=e("./format"),r.exports.parse=e("./parse")},{"./decode":55,"./encode":56,"./format":57,"./parse":59}],59:[function(e,r,t){"use strict";function n(){this.protocol=null,this.slashes=null,this.auth=null,this.port=null,this.hostname=null,this.hash=null,this.search=null,this.pathname=null}function s(e,r){if(e&&e instanceof n)return e;var t=new n;return t.parse(e,r),t}var o=/^([a-z0-9.+-]+:)/i,i=/:[0-9]*$/,a=/^(\/\/?(?!\/)[^\?\s]*)(\?[^\s]*)?$/,c=["<",">",'"',"`"," ","\r","\n","\t"],l=["{","}","|","\\","^","`"].concat(c),u=["'"].concat(l),p=["%","/","?",";","#"].concat(u),h=["/","?","#"],f={javascript:!0,"javascript:":!0},d={http:!0,https:!0,ftp:!0,gopher:!0,file:!0,"http:":!0,"https:":!0,"ftp:":!0,"gopher:":!0,"file:":!0};n.prototype.parse=function(e,r){var t,n,s,i,c,l=e;if(l=l.trim(),!r&&1===e.split("#").length){var u=a.exec(l);if(u)return this.pathname=u[1],u[2]&&(this.search=u[2]),this}var m=o.exec(l);if(m&&(m=m[0],s=m.toLowerCase(),this.protocol=m,l=l.substr(m.length)),(r||m||l.match(/^\/\/[^@\/]+@[^@\/]+/))&&(!(c="//"===l.substr(0,2))||m&&f[m]||(l=l.substr(2),this.slashes=!0)),!f[m]&&(c||m&&!d[m])){var _=-1;for(t=0;t<h.length;t++)(i=l.indexOf(h[t]))!==-1&&(_===-1||i<_)&&(_=i);var g,b;for(b=_===-1?l.lastIndexOf("@"):l.lastIndexOf("@",_),b!==-1&&(g=l.slice(0,b),l=l.slice(b+1),this.auth=g),_=-1,t=0;t<p.length;t++)(i=l.indexOf(p[t]))!==-1&&(_===-1||i<_)&&(_=i);_===-1&&(_=l.length),":"===l[_-1]&&_--;var k=l.slice(0,_);l=l.slice(_),this.parseHost(k),this.hostname=this.hostname||"";var v="["===this.hostname[0]&&"]"===this.hostname[this.hostname.length-1];if(!v){var y=this.hostname.split(/\./);for(t=0,n=y.length;t<n;t++){var x=y[t];if(x&&!x.match(/^[+a-z0-9A-Z_-]{0,63}$/)){for(var C="",A=0,w=x.length;A<w;A++)C+=x.charCodeAt(A)>127?"x":x[A];if(!C.match(/^[+a-z0-9A-Z_-]{0,63}$/)){var D=y.slice(0,t),q=y.slice(t+1),E=x.match(/^([+a-z0-9A-Z_-]{0,63})(.*)$/);E&&(D.push(E[1]),q.unshift(E[2])),q.length&&(l=q.join(".")+l),this.hostname=D.join(".");break}}}}this.hostname.length>255&&(this.hostname=""),v&&(this.hostname=this.hostname.substr(1,this.hostname.length-2))}var S=l.indexOf("#");S!==-1&&(this.hash=l.substr(S),l=l.slice(0,S));var F=l.indexOf("?");return F!==-1&&(this.search=l.substr(F),l=l.slice(0,F)),l&&(this.pathname=l),d[s]&&this.hostname&&!this.pathname&&(this.pathname=""),this},n.prototype.parseHost=function(e){var r=i.exec(e);r&&(r=r[0],":"!==r&&(this.port=r.substr(1)),e=e.substr(0,e.length-r.length)),e&&(this.hostname=e)},r.exports=s},{}],60:[function(r,t,n){(function(r){!function(s){function o(e){throw new RangeError(w[e])}function i(e,r){for(var t=e.length,n=[];t--;)n[t]=r(e[t]);return n}function a(e,r){var t=e.split("@"),n="";return t.length>1&&(n=t[0]+"@",e=t[1]),e=e.replace(/[\x2E\u3002\uFF0E\uFF61]/g,"."),n+i(e.split("."),r).join(".")}function c(e){for(var r,t,n=[],s=0,o=e.length;s<o;)r=e.charCodeAt(s++),r>=55296&&r<=56319&&s<o?(t=e.charCodeAt(s++),56320==(64512&t)?n.push(((1023&r)<<10)+(1023&t)+65536):(n.push(r),s--)):n.push(r);return n}function l(e){return i(e,function(e){var r="";return e>65535&&(e-=65536,r+=q(e>>>10&1023|55296),e=56320|1023&e),r+=q(e)}).join("")}function u(e){return e-48<10?e-22:e-65<26?e-65:e-97<26?e-97:36}function p(e,r){return e+22+75*(e<26)-((0!=r)<<5)}function h(e,r,t){var n=0;for(e=t?D(e/700):e>>1,e+=D(e/r);e>455;n+=36)e=D(e/35);return D(n+36*e/(e+38))}function f(e){var r,t,n,s,i,a,c,p,f,d,m=[],_=e.length,g=0,b=128,k=72;for(t=e.lastIndexOf("-"),t<0&&(t=0),n=0;n<t;++n)e.charCodeAt(n)>=128&&o("not-basic"),m.push(e.charCodeAt(n));for(s=t>0?t+1:0;s<_;){for(i=g,a=1,c=36;s>=_&&o("invalid-input"),p=u(e.charCodeAt(s++)),(p>=36||p>D((x-g)/a))&&o("overflow"),g+=p*a,f=c<=k?1:c>=k+26?26:c-k,!(p<f);c+=36)d=36-f,a>D(x/d)&&o("overflow"),a*=d;r=m.length+1,k=h(g-i,r,0==i),D(g/r)>x-b&&o("overflow"),b+=D(g/r),g%=r,m.splice(g++,0,b)}return l(m)}function d(e){var r,t,n,s,i,a,l,u,f,d,m,_,g,b,k,v=[];for(e=c(e),_=e.length,r=128,t=0,i=72,a=0;a<_;++a)(m=e[a])<128&&v.push(q(m));for(n=s=v.length,s&&v.push("-");n<_;){for(l=x,a=0;a<_;++a)(m=e[a])>=r&&m<l&&(l=m);for(g=n+1,l-r>D((x-t)/g)&&o("overflow"),t+=(l-r)*g,r=l,a=0;a<_;++a)if(m=e[a],m<r&&++t>x&&o("overflow"),m==r){for(u=t,f=36;d=f<=i?1:f>=i+26?26:f-i,!(u<d);f+=36)k=u-d,b=36-d,v.push(q(p(d+k%b,0))),u=D(k/b);v.push(q(p(u,0))),i=h(t,g,n==s),t=0,++n}++t,++r}return v.join("")}function m(e){return a(e,function(e){return C.test(e)?f(e.slice(4).toLowerCase()):e})}function _(e){return a(e,function(e){return A.test(e)?"xn--"+d(e):e})}var g="object"==typeof n&&n&&!n.nodeType&&n,b="object"==typeof t&&t&&!t.nodeType&&t,k="object"==typeof r&&r;k.global!==k&&k.window!==k&&k.self!==k||(s=k);var v,y,x=2147483647,C=/^xn--/,A=/[^\x20-\x7E]/,w={overflow:"Overflow: input needs wider integers to process","not-basic":"Illegal input >= 0x80 (not a basic code point)","invalid-input":"Invalid input"},D=Math.floor,q=String.fromCharCode;if(v={version:"1.4.1",ucs2:{decode:c,encode:l},decode:f,encode:d,toASCII:_,toUnicode:m},"function"==typeof e&&"object"==typeof e.amd&&e.amd)e("punycode",function(){return v});else if(g&&b)if(t.exports==g)b.exports=v;else for(y in v)v.hasOwnProperty(y)&&(g[y]=v[y]);else s.punycode=v}(this)}).call(this,"undefined"!=typeof global?global:"undefined"!=typeof self?self:"undefined"!=typeof window?window:{})},{}],61:[function(e,r,t){r.exports=/[\0-\x1F\x7F-\x9F]/},{}],62:[function(e,r,t){r.exports=/[\xAD\u0600-\u0605\u061C\u06DD\u070F\u08E2\u180E\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u206F\uFEFF\uFFF9-\uFFFB]|\uD804\uDCBD|\uD82F[\uDCA0-\uDCA3]|\uD834[\uDD73-\uDD7A]|\uDB40[\uDC01\uDC20-\uDC7F]/},{}],63:[function(e,r,t){r.exports=/[!-#%-\*,-\/:;\?@\[-\]_\{\}\xA1\xA7\xAB\xB6\xB7\xBB\xBF\u037E\u0387\u055A-\u055F\u0589\u058A\u05BE\u05C0\u05C3\u05C6\u05F3\u05F4\u0609\u060A\u060C\u060D\u061B\u061E\u061F\u066A-\u066D\u06D4\u0700-\u070D\u07F7-\u07F9\u0830-\u083E\u085E\u0964\u0965\u0970\u0AF0\u0DF4\u0E4F\u0E5A\u0E5B\u0F04-\u0F12\u0F14\u0F3A-\u0F3D\u0F85\u0FD0-\u0FD4\u0FD9\u0FDA\u104A-\u104F\u10FB\u1360-\u1368\u1400\u166D\u166E\u169B\u169C\u16EB-\u16ED\u1735\u1736\u17D4-\u17D6\u17D8-\u17DA\u1800-\u180A\u1944\u1945\u1A1E\u1A1F\u1AA0-\u1AA6\u1AA8-\u1AAD\u1B5A-\u1B60\u1BFC-\u1BFF\u1C3B-\u1C3F\u1C7E\u1C7F\u1CC0-\u1CC7\u1CD3\u2010-\u2027\u2030-\u2043\u2045-\u2051\u2053-\u205E\u207D\u207E\u208D\u208E\u2308-\u230B\u2329\u232A\u2768-\u2775\u27C5\u27C6\u27E6-\u27EF\u2983-\u2998\u29D8-\u29DB\u29FC\u29FD\u2CF9-\u2CFC\u2CFE\u2CFF\u2D70\u2E00-\u2E2E\u2E30-\u2E44\u3001-\u3003\u3008-\u3011\u3014-\u301F\u3030\u303D\u30A0\u30FB\uA4FE\uA4FF\uA60D-\uA60F\uA673\uA67E\uA6F2-\uA6F7\uA874-\uA877\uA8CE\uA8CF\uA8F8-\uA8FA\uA8FC\uA92E\uA92F\uA95F\uA9C1-\uA9CD\uA9DE\uA9DF\uAA5C-\uAA5F\uAADE\uAADF\uAAF0\uAAF1\uABEB\uFD3E\uFD3F\uFE10-\uFE19\uFE30-\uFE52\uFE54-\uFE61\uFE63\uFE68\uFE6A\uFE6B\uFF01-\uFF03\uFF05-\uFF0A\uFF0C-\uFF0F\uFF1A\uFF1B\uFF1F\uFF20\uFF3B-\uFF3D\uFF3F\uFF5B\uFF5D\uFF5F-\uFF65]|\uD800[\uDD00-\uDD02\uDF9F\uDFD0]|\uD801\uDD6F|\uD802[\uDC57\uDD1F\uDD3F\uDE50-\uDE58\uDE7F\uDEF0-\uDEF6\uDF39-\uDF3F\uDF99-\uDF9C]|\uD804[\uDC47-\uDC4D\uDCBB\uDCBC\uDCBE-\uDCC1\uDD40-\uDD43\uDD74\uDD75\uDDC5-\uDDC9\uDDCD\uDDDB\uDDDD-\uDDDF\uDE38-\uDE3D\uDEA9]|\uD805[\uDC4B-\uDC4F\uDC5B\uDC5D\uDCC6\uDDC1-\uDDD7\uDE41-\uDE43\uDE60-\uDE6C\uDF3C-\uDF3E]|\uD807[\uDC41-\uDC45\uDC70\uDC71]|\uD809[\uDC70-\uDC74]|\uD81A[\uDE6E\uDE6F\uDEF5\uDF37-\uDF3B\uDF44]|\uD82F\uDC9F|\uD836[\uDE87-\uDE8B]|\uD83A[\uDD5E\uDD5F]/},{}],64:[function(e,r,t){r.exports=/[ \xA0\u1680\u2000-\u200A\u202F\u205F\u3000]/},{}],65:[function(e,r,t){"use strict";t.Any=e("./properties/Any/regex"),t.Cc=e("./categories/Cc/regex"),t.Cf=e("./categories/Cf/regex"),t.P=e("./categories/P/regex"),t.Z=e("./categories/Z/regex")},{"./categories/Cc/regex":61,"./categories/Cf/regex":62,"./categories/P/regex":63,"./categories/Z/regex":64,"./properties/Any/regex":66}],66:[function(e,r,t){r.exports=/[\0-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF][\uDC00-\uDFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF]/},{}],67:[function(e,r,t){"use strict";r.exports=e("./lib/")},{"./lib/":9}]},{},[67])(67)});

  return module.exports;
})();require['./helpers'] = (function() {
  var exports = {}, module = {exports: exports};
  // Generated by CoffeeScript 2.0.0-alpha1
(function() {
  var buildLocationData, extend, flatten, md, ref, repeat, syntaxErrorToString;

  md = require('markdown-it')();

  exports.starts = function(string, literal, start) {
    return literal === string.substr(start, literal.length);
  };

  exports.ends = function(string, literal, back) {
    var len;
    len = literal.length;
    return literal === string.substr(string.length - len - (back || 0), len);
  };

  exports.repeat = repeat = function(str, n) {
    var res;
    res = '';
    while (n > 0) {
      if (n & 1) {
        res += str;
      }
      n >>>= 1;
      str += str;
    }
    return res;
  };

  exports.compact = function(array) {
    var item, j, len1, results;
    results = [];
    for (j = 0, len1 = array.length; j < len1; j++) {
      item = array[j];
      if (item) {
        results.push(item);
      }
    }
    return results;
  };

  exports.count = function(string, substr) {
    var num, pos;
    num = pos = 0;
    if (!substr.length) {
      return 1 / 0;
    }
    while (pos = 1 + string.indexOf(substr, pos)) {
      num++;
    }
    return num;
  };

  exports.merge = function(options, overrides) {
    return extend(extend({}, options), overrides);
  };

  extend = exports.extend = function(object, properties) {
    var key, val;
    for (key in properties) {
      val = properties[key];
      object[key] = val;
    }
    return object;
  };

  exports.flatten = flatten = function(array) {
    var element, flattened, j, len1;
    flattened = [];
    for (j = 0, len1 = array.length; j < len1; j++) {
      element = array[j];
      if ('[object Array]' === Object.prototype.toString.call(element)) {
        flattened = flattened.concat(flatten(element));
      } else {
        flattened.push(element);
      }
    }
    return flattened;
  };

  exports.del = function(obj, key) {
    var val;
    val = obj[key];
    delete obj[key];
    return val;
  };

  exports.some = (ref = Array.prototype.some) != null ? ref : function(fn) {
    var e, j, len1, ref1;
    ref1 = this;
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      e = ref1[j];
      if (fn(e)) {
        return true;
      }
    }
    return false;
  };

  exports.invertLiterate = function(code) {
    var out;
    out = [];
    md.renderer.rules = {
      code_block: function(tokens, idx, options, env, slf) {
        var i, j, len1, line, lines, results, startLine;
        startLine = tokens[idx].map[0];
        lines = tokens[idx].content.split('\n');
        results = [];
        for (i = j = 0, len1 = lines.length; j < len1; i = ++j) {
          line = lines[i];
          results.push(out[startLine + i] = line);
        }
        return results;
      }
    };
    md.render(code);
    return out.join('\n');
  };

  buildLocationData = function(first, last) {
    if (!last) {
      return first;
    } else {
      return {
        first_line: first.first_line,
        first_column: first.first_column,
        last_line: last.last_line,
        last_column: last.last_column
      };
    }
  };

  exports.addLocationDataFn = function(first, last) {
    return function(obj) {
      if (((typeof obj) === 'object') && (!!obj['updateLocationDataIfMissing'])) {
        obj.updateLocationDataIfMissing(buildLocationData(first, last));
      }
      return obj;
    };
  };

  exports.locationDataToString = function(obj) {
    var locationData;
    if (("2" in obj) && ("first_line" in obj[2])) {
      locationData = obj[2];
    } else if ("first_line" in obj) {
      locationData = obj;
    }
    if (locationData) {
      return `${locationData.first_line + 1}:${locationData.first_column + 1}-` + `${locationData.last_line + 1}:${locationData.last_column + 1}`;
    } else {
      return "No location data";
    }
  };

  exports.baseFileName = function(file, stripExt = false, useWinPathSep = false) {
    var parts, pathSep;
    pathSep = useWinPathSep ? /\\|\// : /\//;
    parts = file.split(pathSep);
    file = parts[parts.length - 1];
    if (!(stripExt && file.indexOf('.') >= 0)) {
      return file;
    }
    parts = file.split('.');
    parts.pop();
    if (parts[parts.length - 1] === 'coffee' && parts.length > 1) {
      parts.pop();
    }
    return parts.join('.');
  };

  exports.isCoffee = function(file) {
    return /\.((lit)?coffee|coffee\.md)$/.test(file);
  };

  exports.isLiterate = function(file) {
    return /\.(litcoffee|coffee\.md)$/.test(file);
  };

  exports.throwSyntaxError = function(message, location) {
    var error;
    error = new SyntaxError(message);
    error.location = location;
    error.toString = syntaxErrorToString;
    error.stack = error.toString();
    throw error;
  };

  exports.updateSyntaxError = function(error, code, filename) {
    if (error.toString === syntaxErrorToString) {
      error.code || (error.code = code);
      error.filename || (error.filename = filename);
      error.stack = error.toString();
    }
    return error;
  };

  syntaxErrorToString = function() {
    var codeLine, colorize, colorsEnabled, end, filename, first_column, first_line, last_column, last_line, marker, ref1, ref2, ref3, start;
    if (!(this.code && this.location)) {
      return Error.prototype.toString.call(this);
    }
    ({first_line, first_column, last_line, last_column} = this.location);
    if (last_line == null) {
      last_line = first_line;
    }
    if (last_column == null) {
      last_column = first_column;
    }
    filename = this.filename || '[stdin]';
    codeLine = this.code.split('\n')[first_line];
    start = first_column;
    end = first_line === last_line ? last_column + 1 : codeLine.length;
    marker = codeLine.slice(0, start).replace(/[^\s]/g, ' ') + repeat('^', end - start);
    if (typeof process !== "undefined" && process !== null) {
      colorsEnabled = ((ref1 = process.stdout) != null ? ref1.isTTY : void 0) && !((ref2 = process.env) != null ? ref2.NODE_DISABLE_COLORS : void 0);
    }
    if ((ref3 = this.colorful) != null ? ref3 : colorsEnabled) {
      colorize = function(str) {
        return `\x1B[1;31m${str}\x1B[0m`;
      };
      codeLine = codeLine.slice(0, start) + colorize(codeLine.slice(start, end)) + codeLine.slice(end);
      marker = colorize(marker);
    }
    return `${filename}:${first_line + 1}:${first_column + 1}: error: ${this.message}\n${codeLine}\n${marker}`;
  };

  exports.nameWhitespaceCharacter = function(string) {
    switch (string) {
      case ' ':
        return 'space';
      case '\n':
        return 'newline';
      case '\r':
        return 'carriage return';
      case '\t':
        return 'tab';
      default:
        return string;
    }
  };

}).call(this);

  return module.exports;
})();require['./rewriter'] = (function() {
  var exports = {}, module = {exports: exports};
  // Generated by CoffeeScript 2.0.0-alpha1
(function() {
  var BALANCED_PAIRS, CALL_CLOSERS, EXPRESSION_CLOSE, EXPRESSION_END, EXPRESSION_START, IMPLICIT_CALL, IMPLICIT_END, IMPLICIT_FUNC, IMPLICIT_UNSPACED_CALL, INVERSES, LINEBREAKS, SINGLE_CLOSERS, SINGLE_LINERS, generate, k, left, len, rite,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  generate = function(tag, value, origin) {
    var tok;
    tok = [tag, value];
    tok.generated = true;
    if (origin) {
      tok.origin = origin;
    }
    return tok;
  };

  exports.Rewriter = (function() {
    class Rewriter {
      rewrite(tokens1) {
        this.tokens = tokens1;
        this.removeLeadingNewlines();
        this.closeOpenCalls();
        this.closeOpenIndexes();
        this.normalizeLines();
        this.tagPostfixConditionals();
        this.addImplicitBracesAndParens();
        this.addLocationDataToGeneratedTokens();
        this.fixOutdentLocationData();
        return this.tokens;
      }

      scanTokens(block) {
        var i, token, tokens;
        ({tokens} = this);
        i = 0;
        while (token = tokens[i]) {
          i += block.call(this, token, i, tokens);
        }
        return true;
      }

      detectEnd(i, condition, action) {
        var levels, ref, ref1, token, tokens;
        ({tokens} = this);
        levels = 0;
        while (token = tokens[i]) {
          if (levels === 0 && condition.call(this, token, i)) {
            return action.call(this, token, i);
          }
          if (!token || levels < 0) {
            return action.call(this, token, i - 1);
          }
          if (ref = token[0], indexOf.call(EXPRESSION_START, ref) >= 0) {
            levels += 1;
          } else if (ref1 = token[0], indexOf.call(EXPRESSION_END, ref1) >= 0) {
            levels -= 1;
          }
          i += 1;
        }
        return i - 1;
      }

      removeLeadingNewlines() {
        var i, k, len, ref, tag;
        ref = this.tokens;
        for (i = k = 0, len = ref.length; k < len; i = ++k) {
          [tag] = ref[i];
          if (tag !== 'TERMINATOR') {
            break;
          }
        }
        if (i) {
          return this.tokens.splice(0, i);
        }
      }

      closeOpenCalls() {
        var action, condition;
        condition = function(token, i) {
          var ref;
          return ((ref = token[0]) === ')' || ref === 'CALL_END') || token[0] === 'OUTDENT' && this.tag(i - 1) === ')';
        };
        action = function(token, i) {
          return this.tokens[token[0] === 'OUTDENT' ? i - 1 : i][0] = 'CALL_END';
        };
        return this.scanTokens(function(token, i) {
          if (token[0] === 'CALL_START') {
            this.detectEnd(i + 1, condition, action);
          }
          return 1;
        });
      }

      closeOpenIndexes() {
        var action, condition;
        condition = function(token, i) {
          var ref;
          return (ref = token[0]) === ']' || ref === 'INDEX_END';
        };
        action = function(token, i) {
          return token[0] = 'INDEX_END';
        };
        return this.scanTokens(function(token, i) {
          if (token[0] === 'INDEX_START') {
            this.detectEnd(i + 1, condition, action);
          }
          return 1;
        });
      }

      indexOfTag(i, ...pattern) {
        var fuzz, j, k, ref, ref1;
        fuzz = 0;
        for (j = k = 0, ref = pattern.length; 0 <= ref ? k < ref : k > ref; j = 0 <= ref ? ++k : --k) {
          while (this.tag(i + j + fuzz) === 'HERECOMMENT') {
            fuzz += 2;
          }
          if (pattern[j] == null) {
            continue;
          }
          if (typeof pattern[j] === 'string') {
            pattern[j] = [pattern[j]];
          }
          if (ref1 = this.tag(i + j + fuzz), indexOf.call(pattern[j], ref1) < 0) {
            return -1;
          }
        }
        return i + j + fuzz - 1;
      }

      looksObjectish(j) {
        var end, index;
        if (this.indexOfTag(j, '@', null, ':') > -1 || this.indexOfTag(j, null, ':') > -1) {
          return true;
        }
        index = this.indexOfTag(j, EXPRESSION_START);
        if (index > -1) {
          end = null;
          this.detectEnd(index + 1, (function(token) {
            var ref;
            return ref = token[0], indexOf.call(EXPRESSION_END, ref) >= 0;
          }), (function(token, i) {
            return end = i;
          }));
          if (this.tag(end + 1) === ':') {
            return true;
          }
        }
        return false;
      }

      findTagsBackwards(i, tags) {
        var backStack, ref, ref1, ref2, ref3, ref4, ref5;
        backStack = [];
        while (i >= 0 && (backStack.length || (ref2 = this.tag(i), indexOf.call(tags, ref2) < 0) && ((ref3 = this.tag(i), indexOf.call(EXPRESSION_START, ref3) < 0) || this.tokens[i].generated) && (ref4 = this.tag(i), indexOf.call(LINEBREAKS, ref4) < 0))) {
          if (ref = this.tag(i), indexOf.call(EXPRESSION_END, ref) >= 0) {
            backStack.push(this.tag(i));
          }
          if ((ref1 = this.tag(i), indexOf.call(EXPRESSION_START, ref1) >= 0) && backStack.length) {
            backStack.pop();
          }
          i -= 1;
        }
        return ref5 = this.tag(i), indexOf.call(tags, ref5) >= 0;
      }

      addImplicitBracesAndParens() {
        var stack, start;
        stack = [];
        start = null;
        return this.scanTokens(function(token, i, tokens) {
          var endImplicitCall, endImplicitObject, forward, inImplicit, inImplicitCall, inImplicitControl, inImplicitObject, newLine, nextTag, offset, prevTag, prevToken, ref, ref1, ref2, s, sameLine, stackIdx, stackTag, stackTop, startIdx, startImplicitCall, startImplicitObject, startsLine, tag;
          [tag] = token;
          [prevTag] = prevToken = i > 0 ? tokens[i - 1] : [];
          [nextTag] = i < tokens.length - 1 ? tokens[i + 1] : [];
          stackTop = function() {
            return stack[stack.length - 1];
          };
          startIdx = i;
          forward = function(n) {
            return i - startIdx + n;
          };
          inImplicit = function() {
            var ref, ref1;
            return (ref = stackTop()) != null ? (ref1 = ref[2]) != null ? ref1.ours : void 0 : void 0;
          };
          inImplicitCall = function() {
            var ref;
            return inImplicit() && ((ref = stackTop()) != null ? ref[0] : void 0) === '(';
          };
          inImplicitObject = function() {
            var ref;
            return inImplicit() && ((ref = stackTop()) != null ? ref[0] : void 0) === '{';
          };
          inImplicitControl = function() {
            var ref;
            return inImplicit && ((ref = stackTop()) != null ? ref[0] : void 0) === 'CONTROL';
          };
          startImplicitCall = function(j) {
            var idx;
            idx = j != null ? j : i;
            stack.push([
              '(', idx, {
                ours: true
              }
            ]);
            tokens.splice(idx, 0, generate('CALL_START', '('));
            if (j == null) {
              return i += 1;
            }
          };
          endImplicitCall = function() {
            stack.pop();
            tokens.splice(i, 0, generate('CALL_END', ')', ['', 'end of input', token[2]]));
            return i += 1;
          };
          startImplicitObject = function(j, startsLine = true) {
            var idx, val;
            idx = j != null ? j : i;
            stack.push([
              '{', idx, {
                sameLine: true,
                startsLine: startsLine,
                ours: true
              }
            ]);
            val = new String('{');
            val.generated = true;
            tokens.splice(idx, 0, generate('{', val, token));
            if (j == null) {
              return i += 1;
            }
          };
          endImplicitObject = function(j) {
            j = j != null ? j : i;
            stack.pop();
            tokens.splice(j, 0, generate('}', '}', token));
            return i += 1;
          };
          if (inImplicitCall() && (tag === 'IF' || tag === 'TRY' || tag === 'FINALLY' || tag === 'CATCH' || tag === 'CLASS' || tag === 'SWITCH')) {
            stack.push([
              'CONTROL', i, {
                ours: true
              }
            ]);
            return forward(1);
          }
          if (tag === 'INDENT' && inImplicit()) {
            if (prevTag !== '=>' && prevTag !== '->' && prevTag !== '[' && prevTag !== '(' && prevTag !== ',' && prevTag !== '{' && prevTag !== 'TRY' && prevTag !== 'ELSE' && prevTag !== '=') {
              while (inImplicitCall()) {
                endImplicitCall();
              }
            }
            if (inImplicitControl()) {
              stack.pop();
            }
            stack.push([tag, i]);
            return forward(1);
          }
          if (indexOf.call(EXPRESSION_START, tag) >= 0) {
            stack.push([tag, i]);
            return forward(1);
          }
          if (indexOf.call(EXPRESSION_END, tag) >= 0) {
            while (inImplicit()) {
              if (inImplicitCall()) {
                endImplicitCall();
              } else if (inImplicitObject()) {
                endImplicitObject();
              } else {
                stack.pop();
              }
            }
            start = stack.pop();
          }
          if ((indexOf.call(IMPLICIT_FUNC, tag) >= 0 && token.spaced || tag === '?' && i > 0 && !tokens[i - 1].spaced) && (indexOf.call(IMPLICIT_CALL, nextTag) >= 0 || indexOf.call(IMPLICIT_UNSPACED_CALL, nextTag) >= 0 && !((ref = tokens[i + 1]) != null ? ref.spaced : void 0) && !((ref1 = tokens[i + 1]) != null ? ref1.newLine : void 0))) {
            if (tag === '?') {
              tag = token[0] = 'FUNC_EXIST';
            }
            startImplicitCall(i + 1);
            return forward(2);
          }
          if (indexOf.call(IMPLICIT_FUNC, tag) >= 0 && this.indexOfTag(i + 1, 'INDENT') > -1 && this.looksObjectish(i + 2) && !this.findTagsBackwards(i, ['CLASS', 'EXTENDS', 'IF', 'CATCH', 'SWITCH', 'LEADING_WHEN', 'FOR', 'WHILE', 'UNTIL'])) {
            startImplicitCall(i + 1);
            stack.push(['INDENT', i + 2]);
            return forward(3);
          }
          if (tag === ':') {
            s = (function() {
              var ref2;
              switch (false) {
                case ref2 = this.tag(i - 1), indexOf.call(EXPRESSION_END, ref2) < 0:
                  return start[1];
                case this.tag(i - 2) !== '@':
                  return i - 2;
                default:
                  return i - 1;
              }
            }).call(this);
            while (this.tag(s - 2) === 'HERECOMMENT') {
              s -= 2;
            }
            this.insideForDeclaration = nextTag === 'FOR';
            startsLine = s === 0 || (ref2 = this.tag(s - 1), indexOf.call(LINEBREAKS, ref2) >= 0) || tokens[s - 1].newLine;
            if (stackTop()) {
              [stackTag, stackIdx] = stackTop();
              if ((stackTag === '{' || stackTag === 'INDENT' && this.tag(stackIdx - 1) === '{') && (startsLine || this.tag(s - 1) === ',' || this.tag(s - 1) === '{')) {
                return forward(1);
              }
            }
            startImplicitObject(s, !!startsLine);
            return forward(2);
          }
          if (inImplicitObject() && indexOf.call(LINEBREAKS, tag) >= 0) {
            stackTop()[2].sameLine = false;
          }
          newLine = prevTag === 'OUTDENT' || prevToken.newLine;
          if (indexOf.call(IMPLICIT_END, tag) >= 0 || indexOf.call(CALL_CLOSERS, tag) >= 0 && newLine) {
            while (inImplicit()) {
              [stackTag, stackIdx, {sameLine, startsLine}] = stackTop();
              if (inImplicitCall() && prevTag !== ',') {
                endImplicitCall();
              } else if (inImplicitObject() && !this.insideForDeclaration && sameLine && tag !== 'TERMINATOR' && prevTag !== ':') {
                endImplicitObject();
              } else if (inImplicitObject() && tag === 'TERMINATOR' && prevTag !== ',' && !(startsLine && this.looksObjectish(i + 1))) {
                if (nextTag === 'HERECOMMENT') {
                  return forward(1);
                }
                endImplicitObject();
              } else {
                break;
              }
            }
          }
          if (tag === ',' && !this.looksObjectish(i + 1) && inImplicitObject() && !this.insideForDeclaration && (nextTag !== 'TERMINATOR' || !this.looksObjectish(i + 2))) {
            offset = nextTag === 'OUTDENT' ? 1 : 0;
            while (inImplicitObject()) {
              endImplicitObject(i + offset);
            }
          }
          return forward(1);
        });
      }

      addLocationDataToGeneratedTokens() {
        return this.scanTokens(function(token, i, tokens) {
          var column, line, nextLocation, prevLocation, ref, ref1;
          if (token[2]) {
            return 1;
          }
          if (!(token.generated || token.explicit)) {
            return 1;
          }
          if (token[0] === '{' && (nextLocation = (ref = tokens[i + 1]) != null ? ref[2] : void 0)) {
            ({
              first_line: line,
              first_column: column
            } = nextLocation);
          } else if (prevLocation = (ref1 = tokens[i - 1]) != null ? ref1[2] : void 0) {
            ({
              last_line: line,
              last_column: column
            } = prevLocation);
          } else {
            line = column = 0;
          }
          token[2] = {
            first_line: line,
            first_column: column,
            last_line: line,
            last_column: column
          };
          return 1;
        });
      }

      fixOutdentLocationData() {
        return this.scanTokens(function(token, i, tokens) {
          var prevLocationData;
          if (!(token[0] === 'OUTDENT' || (token.generated && token[0] === 'CALL_END') || (token.generated && token[0] === '}'))) {
            return 1;
          }
          prevLocationData = tokens[i - 1][2];
          token[2] = {
            first_line: prevLocationData.last_line,
            first_column: prevLocationData.last_column,
            last_line: prevLocationData.last_line,
            last_column: prevLocationData.last_column
          };
          return 1;
        });
      }

      normalizeLines() {
        var action, condition, indent, outdent, starter;
        starter = indent = outdent = null;
        condition = function(token, i) {
          var ref, ref1, ref2, ref3;
          return token[1] !== ';' && (ref = token[0], indexOf.call(SINGLE_CLOSERS, ref) >= 0) && !(token[0] === 'TERMINATOR' && (ref1 = this.tag(i + 1), indexOf.call(EXPRESSION_CLOSE, ref1) >= 0)) && !(token[0] === 'ELSE' && starter !== 'THEN') && !(((ref2 = token[0]) === 'CATCH' || ref2 === 'FINALLY') && (starter === '->' || starter === '=>')) || (ref3 = token[0], indexOf.call(CALL_CLOSERS, ref3) >= 0) && this.tokens[i - 1].newLine;
        };
        action = function(token, i) {
          return this.tokens.splice((this.tag(i - 1) === ',' ? i - 1 : i), 0, outdent);
        };
        return this.scanTokens(function(token, i, tokens) {
          var j, k, ref, ref1, tag;
          [tag] = token;
          if (tag === 'TERMINATOR') {
            if (this.tag(i + 1) === 'ELSE' && this.tag(i - 1) !== 'OUTDENT') {
              tokens.splice(i, 1, ...this.indentation());
              return 1;
            }
            if (ref = this.tag(i + 1), indexOf.call(EXPRESSION_CLOSE, ref) >= 0) {
              tokens.splice(i, 1);
              return 0;
            }
          }
          if (tag === 'CATCH') {
            for (j = k = 1; k <= 2; j = ++k) {
              if (!((ref1 = this.tag(i + j)) === 'OUTDENT' || ref1 === 'TERMINATOR' || ref1 === 'FINALLY')) {
                continue;
              }
              tokens.splice(i + j, 0, ...this.indentation());
              return 2 + j;
            }
          }
          if (indexOf.call(SINGLE_LINERS, tag) >= 0 && this.tag(i + 1) !== 'INDENT' && !(tag === 'ELSE' && this.tag(i + 1) === 'IF')) {
            starter = tag;
            [indent, outdent] = this.indentation(tokens[i]);
            if (starter === 'THEN') {
              indent.fromThen = true;
            }
            tokens.splice(i + 1, 0, indent);
            this.detectEnd(i + 2, condition, action);
            if (tag === 'THEN') {
              tokens.splice(i, 1);
            }
            return 1;
          }
          return 1;
        });
      }

      tagPostfixConditionals() {
        var action, condition, original;
        original = null;
        condition = function(token, i) {
          var prevTag, tag;
          [tag] = token;
          [prevTag] = this.tokens[i - 1];
          return tag === 'TERMINATOR' || (tag === 'INDENT' && indexOf.call(SINGLE_LINERS, prevTag) < 0);
        };
        action = function(token, i) {
          if (token[0] !== 'INDENT' || (token.generated && !token.fromThen)) {
            return original[0] = 'POST_' + original[0];
          }
        };
        return this.scanTokens(function(token, i) {
          if (token[0] !== 'IF') {
            return 1;
          }
          original = token;
          this.detectEnd(i + 1, condition, action);
          return 1;
        });
      }

      indentation(origin) {
        var indent, outdent;
        indent = ['INDENT', 2];
        outdent = ['OUTDENT', 2];
        if (origin) {
          indent.generated = outdent.generated = true;
          indent.origin = outdent.origin = origin;
        } else {
          indent.explicit = outdent.explicit = true;
        }
        return [indent, outdent];
      }

      tag(i) {
        var ref;
        return (ref = this.tokens[i]) != null ? ref[0] : void 0;
      }

    };

    Rewriter.prototype.generate = generate;

    return Rewriter;

  })();

  BALANCED_PAIRS = [['(', ')'], ['[', ']'], ['{', '}'], ['INDENT', 'OUTDENT'], ['CALL_START', 'CALL_END'], ['PARAM_START', 'PARAM_END'], ['INDEX_START', 'INDEX_END'], ['STRING_START', 'STRING_END'], ['REGEX_START', 'REGEX_END']];

  exports.INVERSES = INVERSES = {};

  EXPRESSION_START = [];

  EXPRESSION_END = [];

  for (k = 0, len = BALANCED_PAIRS.length; k < len; k++) {
    [left, rite] = BALANCED_PAIRS[k];
    EXPRESSION_START.push(INVERSES[rite] = left);
    EXPRESSION_END.push(INVERSES[left] = rite);
  }

  EXPRESSION_CLOSE = ['CATCH', 'THEN', 'ELSE', 'FINALLY'].concat(EXPRESSION_END);

  IMPLICIT_FUNC = ['IDENTIFIER', 'PROPERTY', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END', '@', 'THIS'];

  IMPLICIT_CALL = ['IDENTIFIER', 'PROPERTY', 'NUMBER', 'INFINITY', 'NAN', 'STRING', 'STRING_START', 'REGEX', 'REGEX_START', 'JS', 'NEW', 'PARAM_START', 'CLASS', 'IF', 'TRY', 'SWITCH', 'THIS', 'UNDEFINED', 'NULL', 'BOOL', 'UNARY', 'YIELD', 'AWAIT', 'UNARY_MATH', 'SUPER', 'THROW', '@', '->', '=>', '[', '(', '{', '--', '++'];

  IMPLICIT_UNSPACED_CALL = ['+', '-'];

  IMPLICIT_END = ['POST_IF', 'FOR', 'WHILE', 'UNTIL', 'WHEN', 'BY', 'LOOP', 'TERMINATOR'];

  SINGLE_LINERS = ['ELSE', '->', '=>', 'TRY', 'FINALLY', 'THEN'];

  SINGLE_CLOSERS = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN'];

  LINEBREAKS = ['TERMINATOR', 'INDENT', 'OUTDENT'];

  CALL_CLOSERS = ['.', '?.', '::', '?::'];

}).call(this);

  return module.exports;
})();require['./lexer'] = (function() {
  var exports = {}, module = {exports: exports};
  // Generated by CoffeeScript 2.0.0-alpha1
(function() {
  var BOM, BOOL, CALLABLE, CODE, COFFEE_ALIASES, COFFEE_ALIAS_MAP, COFFEE_KEYWORDS, COMMENT, COMPARE, COMPOUND_ASSIGN, HERECOMMENT_ILLEGAL, HEREDOC_DOUBLE, HEREDOC_INDENT, HEREDOC_SINGLE, HEREGEX, HEREGEX_OMIT, HERE_JSTOKEN, IDENTIFIER, INDENTABLE_CLOSERS, INDEXABLE, INVERSES, JSTOKEN, JS_KEYWORDS, LEADING_BLANK_LINE, LINE_BREAK, LINE_CONTINUER, Lexer, MATH, MULTI_DENT, NOT_REGEX, NUMBER, OPERATOR, POSSIBLY_DIVISION, REGEX, REGEX_FLAGS, REGEX_ILLEGAL, REGEX_INVALID_ESCAPE, RELATION, RESERVED, Rewriter, SHIFT, SIMPLE_STRING_OMIT, STRICT_PROSCRIBED, STRING_DOUBLE, STRING_INVALID_ESCAPE, STRING_OMIT, STRING_SINGLE, STRING_START, TRAILING_BLANK_LINE, TRAILING_SPACES, UNARY, UNARY_MATH, VALID_FLAGS, WHITESPACE, compact, count, invertLiterate, isForFrom, isUnassignable, key, locationDataToString, repeat, starts, throwSyntaxError,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  ({Rewriter, INVERSES} = require('./rewriter'));

  ({count, starts, compact, repeat, invertLiterate, locationDataToString, throwSyntaxError} = require('./helpers'));

  exports.Lexer = Lexer = class Lexer {
    tokenize(code, opts = {}) {
      var consumed, end, i;
      this.literate = opts.literate;
      this.indent = 0;
      this.baseIndent = 0;
      this.indebt = 0;
      this.outdebt = 0;
      this.indents = [];
      this.indentLiteral = '';
      this.ends = [];
      this.tokens = [];
      this.seenFor = false;
      this.seenImport = false;
      this.seenExport = false;
      this.importSpecifierList = false;
      this.exportSpecifierList = false;
      this.chunkLine = opts.line || 0;
      this.chunkColumn = opts.column || 0;
      code = this.clean(code);
      i = 0;
      while (this.chunk = code.slice(i)) {
        consumed = this.identifierToken() || this.commentToken() || this.whitespaceToken() || this.lineToken() || this.stringToken() || this.numberToken() || this.regexToken() || this.jsToken() || this.literalToken();
        [this.chunkLine, this.chunkColumn] = this.getLineAndColumnFromChunk(consumed);
        i += consumed;
        if (opts.untilBalanced && this.ends.length === 0) {
          return {
            tokens: this.tokens,
            index: i
          };
        }
      }
      this.closeIndentation();
      if (end = this.ends.pop()) {
        this.error(`missing ${end.tag}`, end.origin[2]);
      }
      if (opts.rewrite === false) {
        return this.tokens;
      }
      return (new Rewriter).rewrite(this.tokens);
    }

    clean(code) {
      if (code.charCodeAt(0) === BOM) {
        code = code.slice(1);
      }
      code = code.replace(/\r/g, '').replace(TRAILING_SPACES, '');
      if (WHITESPACE.test(code)) {
        code = `\n${code}`;
        this.chunkLine--;
      }
      if (this.literate) {
        code = invertLiterate(code);
      }
      return code;
    }

    identifierToken() {
      var alias, colon, colonOffset, id, idLength, input, match, poppedToken, prev, prevprev, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, tag, tagToken;
      if (!(match = IDENTIFIER.exec(this.chunk))) {
        return 0;
      }
      [input, id, colon] = match;
      idLength = id.length;
      poppedToken = void 0;
      if (id === 'own' && this.tag() === 'FOR') {
        this.token('OWN', id);
        return id.length;
      }
      if (id === 'from' && this.tag() === 'YIELD') {
        this.token('FROM', id);
        return id.length;
      }
      if (id === 'as' && this.seenImport) {
        if (this.value() === '*') {
          this.tokens[this.tokens.length - 1][0] = 'IMPORT_ALL';
        } else if (ref = this.value(), indexOf.call(COFFEE_KEYWORDS, ref) >= 0) {
          this.tokens[this.tokens.length - 1][0] = 'IDENTIFIER';
        }
        if ((ref1 = this.tag()) === 'DEFAULT' || ref1 === 'IMPORT_ALL' || ref1 === 'IDENTIFIER') {
          this.token('AS', id);
          return id.length;
        }
      }
      if (id === 'as' && this.seenExport && ((ref2 = this.tag()) === 'IDENTIFIER' || ref2 === 'DEFAULT')) {
        this.token('AS', id);
        return id.length;
      }
      if (id === 'default' && this.seenExport && ((ref3 = this.tag()) === 'EXPORT' || ref3 === 'AS')) {
        this.token('DEFAULT', id);
        return id.length;
      }
      prev = this.prev();
      tag = colon || (prev != null) && (((ref4 = prev[0]) === '.' || ref4 === '?.' || ref4 === '::' || ref4 === '?::') || !prev.spaced && prev[0] === '@') ? 'PROPERTY' : 'IDENTIFIER';
      if (tag === 'IDENTIFIER' && (indexOf.call(JS_KEYWORDS, id) >= 0 || indexOf.call(COFFEE_KEYWORDS, id) >= 0) && !(this.exportSpecifierList && indexOf.call(COFFEE_KEYWORDS, id) >= 0)) {
        tag = id.toUpperCase();
        if (tag === 'WHEN' && (ref5 = this.tag(), indexOf.call(LINE_BREAK, ref5) >= 0)) {
          tag = 'LEADING_WHEN';
        } else if (tag === 'FOR') {
          this.seenFor = true;
        } else if (tag === 'UNLESS') {
          tag = 'IF';
        } else if (tag === 'IMPORT') {
          this.seenImport = true;
        } else if (tag === 'EXPORT') {
          this.seenExport = true;
        } else if (indexOf.call(UNARY, tag) >= 0) {
          tag = 'UNARY';
        } else if (indexOf.call(RELATION, tag) >= 0) {
          if (tag !== 'INSTANCEOF' && this.seenFor) {
            tag = 'FOR' + tag;
            this.seenFor = false;
          } else {
            tag = 'RELATION';
            if (this.value() === '!') {
              poppedToken = this.tokens.pop();
              id = '!' + id;
            }
          }
        }
      } else if (tag === 'IDENTIFIER' && this.seenFor && id === 'from' && isForFrom(prev)) {
        tag = 'FORFROM';
        this.seenFor = false;
      } else if (tag === 'PROPERTY' && prev) {
        if (prev.spaced && (ref6 = prev[0], indexOf.call(CALLABLE, ref6) >= 0) && /^[gs]et$/.test(prev[1])) {
          this.error(`'${prev[1]}' cannot be used as a keyword, or as a function call without parentheses`, prev[2]);
        } else {
          prevprev = this.tokens[this.tokens.length - 2];
          if (((ref7 = prev[0]) === '@' || ref7 === 'THIS') && prevprev && prevprev.spaced && /^[gs]et$/.test(prevprev[1])) {
            this.error(`'${prevprev[1]}' cannot be used as a keyword, or as a function call without parentheses`, prevprev[2]);
          }
        }
      }
      if (tag === 'IDENTIFIER' && indexOf.call(RESERVED, id) >= 0) {
        this.error(`reserved word '${id}'`, {
          length: id.length
        });
      }
      if (tag !== 'PROPERTY') {
        if (indexOf.call(COFFEE_ALIASES, id) >= 0) {
          alias = id;
          id = COFFEE_ALIAS_MAP[id];
        }
        tag = (function() {
          switch (id) {
            case '!':
              return 'UNARY';
            case '==':
            case '!=':
              return 'COMPARE';
            case 'true':
            case 'false':
              return 'BOOL';
            case 'break':
            case 'continue':
            case 'debugger':
              return 'STATEMENT';
            case '&&':
            case '||':
              return id;
            default:
              return tag;
          }
        })();
      }
      tagToken = this.token(tag, id, 0, idLength);
      if (alias) {
        tagToken.origin = [tag, alias, tagToken[2]];
      }
      if (poppedToken) {
        [tagToken[2].first_line, tagToken[2].first_column] = [poppedToken[2].first_line, poppedToken[2].first_column];
      }
      if (colon) {
        colonOffset = input.lastIndexOf(':');
        this.token(':', ':', colonOffset, colon.length);
      }
      return input.length;
    }

    numberToken() {
      var base, lexedLength, match, number, numberValue, tag;
      if (!(match = NUMBER.exec(this.chunk))) {
        return 0;
      }
      number = match[0];
      lexedLength = number.length;
      switch (false) {
        case !/^0[BOX]/.test(number):
          this.error(`radix prefix in '${number}' must be lowercase`, {
            offset: 1
          });
          break;
        case !/^(?!0x).*E/.test(number):
          this.error(`exponential notation in '${number}' must be indicated with a lowercase 'e'`, {
            offset: number.indexOf('E')
          });
          break;
        case !/^0\d*[89]/.test(number):
          this.error(`decimal literal '${number}' must not be prefixed with '0'`, {
            length: lexedLength
          });
          break;
        case !/^0\d+/.test(number):
          this.error(`octal literal '${number}' must be prefixed with '0o'`, {
            length: lexedLength
          });
      }
      base = (function() {
        switch (number.charAt(1)) {
          case 'b':
            return 2;
          case 'o':
            return 8;
          case 'x':
            return 16;
          default:
            return null;
        }
      })();
      numberValue = base != null ? parseInt(number.slice(2), base) : parseFloat(number);
      tag = numberValue === 2e308 ? 'INFINITY' : 'NUMBER';
      this.token(tag, number, 0, lexedLength);
      return lexedLength;
    }

    stringToken() {
      var $, attempt, delimiter, doc, end, heredoc, i, indent, indentRegex, match, prev, quote, ref, regex, token, tokens;
      [quote] = STRING_START.exec(this.chunk) || [];
      if (!quote) {
        return 0;
      }
      prev = this.prev();
      if (prev && this.value() === 'from' && (this.seenImport || this.seenExport)) {
        prev[0] = 'FROM';
      }
      regex = (function() {
        switch (quote) {
          case "'":
            return STRING_SINGLE;
          case '"':
            return STRING_DOUBLE;
          case "'''":
            return HEREDOC_SINGLE;
          case '"""':
            return HEREDOC_DOUBLE;
        }
      })();
      heredoc = quote.length === 3;
      ({
        tokens,
        index: end
      } = this.matchWithInterpolations(regex, quote));
      $ = tokens.length - 1;
      delimiter = quote.charAt(0);
      if (heredoc) {
        indent = null;
        doc = ((function() {
          var j, len, results;
          results = [];
          for (i = j = 0, len = tokens.length; j < len; i = ++j) {
            token = tokens[i];
            if (token[0] === 'NEOSTRING') {
              results.push(token[1]);
            }
          }
          return results;
        })()).join('#{}');
        while (match = HEREDOC_INDENT.exec(doc)) {
          attempt = match[1];
          if (indent === null || (0 < (ref = attempt.length) && ref < indent.length)) {
            indent = attempt;
          }
        }
        if (indent) {
          indentRegex = RegExp(`\\n${indent}`, "g");
        }
        this.mergeInterpolationTokens(tokens, {delimiter}, (value, i) => {
          value = this.formatString(value);
          if (indentRegex) {
            value = value.replace(indentRegex, '\n');
          }
          if (i === 0) {
            value = value.replace(LEADING_BLANK_LINE, '');
          }
          if (i === $) {
            value = value.replace(TRAILING_BLANK_LINE, '');
          }
          return value;
        });
      } else {
        this.mergeInterpolationTokens(tokens, {delimiter}, (value, i) => {
          value = this.formatString(value);
          value = value.replace(SIMPLE_STRING_OMIT, function(match, offset) {
            if ((i === 0 && offset === 0) || (i === $ && offset + match.length === value.length)) {
              return '';
            } else {
              return ' ';
            }
          });
          return value;
        });
      }
      return end;
    }

    commentToken() {
      var comment, here, match;
      if (!(match = this.chunk.match(COMMENT))) {
        return 0;
      }
      [comment, here] = match;
      if (here) {
        if (match = HERECOMMENT_ILLEGAL.exec(comment)) {
          this.error(`block comments cannot contain ${match[0]}`, {
            offset: match.index,
            length: match[0].length
          });
        }
        if (here.indexOf('\n') >= 0) {
          here = here.replace(RegExp(`\\n${repeat(' ', this.indent)}`, "g"), '\n');
        }
        this.token('HERECOMMENT', here, 0, comment.length);
      }
      return comment.length;
    }

    jsToken() {
      var match, script;
      if (!(this.chunk.charAt(0) === '`' && (match = HERE_JSTOKEN.exec(this.chunk) || JSTOKEN.exec(this.chunk)))) {
        return 0;
      }
      script = match[1].replace(/\\+(`|$)/g, function(string) {
        return string.slice(-Math.ceil(string.length / 2));
      });
      this.token('JS', script, 0, match[0].length);
      return match[0].length;
    }

    regexToken() {
      var body, closed, end, flags, index, match, origin, prev, ref, ref1, regex, tokens;
      switch (false) {
        case !(match = REGEX_ILLEGAL.exec(this.chunk)):
          this.error(`regular expressions cannot begin with ${match[2]}`, {
            offset: match.index + match[1].length
          });
          break;
        case !(match = this.matchWithInterpolations(HEREGEX, '///')):
          ({tokens, index} = match);
          break;
        case !(match = REGEX.exec(this.chunk)):
          [regex, body, closed] = match;
          this.validateEscapes(body, {
            isRegex: true,
            offsetInChunk: 1
          });
          index = regex.length;
          prev = this.prev();
          if (prev) {
            if (prev.spaced && (ref = prev[0], indexOf.call(CALLABLE, ref) >= 0)) {
              if (!closed || POSSIBLY_DIVISION.test(regex)) {
                return 0;
              }
            } else if (ref1 = prev[0], indexOf.call(NOT_REGEX, ref1) >= 0) {
              return 0;
            }
          }
          if (!closed) {
            this.error('missing / (unclosed regex)');
          }
          break;
        default:
          return 0;
      }
      [flags] = REGEX_FLAGS.exec(this.chunk.slice(index));
      end = index + flags.length;
      origin = this.makeToken('REGEX', null, 0, end);
      switch (false) {
        case !!VALID_FLAGS.test(flags):
          this.error(`invalid regular expression flags ${flags}`, {
            offset: index,
            length: flags.length
          });
          break;
        case !(regex || tokens.length === 1):
          if (body == null) {
            body = this.formatHeregex(tokens[0][1]);
          }
          this.token('REGEX', `${this.makeDelimitedLiteral(body, {
            delimiter: '/'
          })}${flags}`, 0, end, origin);
          break;
        default:
          this.token('REGEX_START', '(', 0, 0, origin);
          this.token('IDENTIFIER', 'RegExp', 0, 0);
          this.token('CALL_START', '(', 0, 0);
          this.mergeInterpolationTokens(tokens, {
            delimiter: '"',
            double: true
          }, this.formatHeregex);
          if (flags) {
            this.token(',', ',', index - 1, 0);
            this.token('STRING', '"' + flags + '"', index - 1, flags.length);
          }
          this.token(')', ')', end - 1, 0);
          this.token('REGEX_END', ')', end - 1, 0);
      }
      return end;
    }

    lineToken() {
      var diff, indent, match, minLiteralLength, newIndentLiteral, noNewlines, size;
      if (!(match = MULTI_DENT.exec(this.chunk))) {
        return 0;
      }
      indent = match[0];
      this.seenFor = false;
      if (!this.importSpecifierList) {
        this.seenImport = false;
      }
      if (!this.exportSpecifierList) {
        this.seenExport = false;
      }
      size = indent.length - 1 - indent.lastIndexOf('\n');
      noNewlines = this.unfinished();
      newIndentLiteral = size > 0 ? indent.slice(-size) : '';
      if (!/^(.?)\1*$/.exec(newIndentLiteral)) {
        this.error('mixed indentation', {
          offset: indent.length
        });
        return indent.length;
      }
      minLiteralLength = Math.min(newIndentLiteral.length, this.indentLiteral.length);
      if (newIndentLiteral.slice(0, minLiteralLength) !== this.indentLiteral.slice(0, minLiteralLength)) {
        this.error('indentation mismatch', {
          offset: indent.length
        });
        return indent.length;
      }
      if (size - this.indebt === this.indent) {
        if (noNewlines) {
          this.suppressNewlines();
        } else {
          this.newlineToken(0);
        }
        return indent.length;
      }
      if (size > this.indent) {
        if (noNewlines) {
          this.indebt = size - this.indent;
          this.suppressNewlines();
          return indent.length;
        }
        if (!this.tokens.length) {
          this.baseIndent = this.indent = size;
          this.indentLiteral = newIndentLiteral;
          return indent.length;
        }
        diff = size - this.indent + this.outdebt;
        this.token('INDENT', diff, indent.length - size, size);
        this.indents.push(diff);
        this.ends.push({
          tag: 'OUTDENT'
        });
        this.outdebt = this.indebt = 0;
        this.indent = size;
        this.indentLiteral = newIndentLiteral;
      } else if (size < this.baseIndent) {
        this.error('missing indentation', {
          offset: indent.length
        });
      } else {
        this.indebt = 0;
        this.outdentToken(this.indent - size, noNewlines, indent.length);
      }
      return indent.length;
    }

    outdentToken(moveOut, noNewlines, outdentLength) {
      var decreasedIndent, dent, lastIndent, ref;
      decreasedIndent = this.indent - moveOut;
      while (moveOut > 0) {
        lastIndent = this.indents[this.indents.length - 1];
        if (!lastIndent) {
          moveOut = 0;
        } else if (this.outdebt && moveOut <= this.outdebt) {
          this.outdebt -= moveOut;
          moveOut = 0;
        } else {
          dent = this.indents.pop() + this.outdebt;
          if (outdentLength && (ref = this.chunk[outdentLength], indexOf.call(INDENTABLE_CLOSERS, ref) >= 0)) {
            decreasedIndent -= dent - moveOut;
            moveOut = dent;
          }
          this.outdebt = 0;
          this.pair('OUTDENT');
          this.token('OUTDENT', moveOut, 0, outdentLength);
          moveOut -= dent;
        }
      }
      if (dent) {
        this.outdebt -= moveOut;
      }
      while (this.value() === ';') {
        this.tokens.pop();
      }
      if (!(this.tag() === 'TERMINATOR' || noNewlines)) {
        this.token('TERMINATOR', '\n', outdentLength, 0);
      }
      this.indent = decreasedIndent;
      this.indentLiteral = this.indentLiteral.slice(0, decreasedIndent);
      return this;
    }

    whitespaceToken() {
      var match, nline, prev;
      if (!((match = WHITESPACE.exec(this.chunk)) || (nline = this.chunk.charAt(0) === '\n'))) {
        return 0;
      }
      prev = this.prev();
      if (prev) {
        prev[match ? 'spaced' : 'newLine'] = true;
      }
      if (match) {
        return match[0].length;
      } else {
        return 0;
      }
    }

    newlineToken(offset) {
      while (this.value() === ';') {
        this.tokens.pop();
      }
      if (this.tag() !== 'TERMINATOR') {
        this.token('TERMINATOR', '\n', offset, 0);
      }
      return this;
    }

    suppressNewlines() {
      if (this.value() === '\\') {
        this.tokens.pop();
      }
      return this;
    }

    literalToken() {
      var match, message, origin, prev, ref, ref1, ref2, ref3, skipToken, tag, token, value;
      if (match = OPERATOR.exec(this.chunk)) {
        [value] = match;
        if (CODE.test(value)) {
          this.tagParameters();
        }
      } else {
        value = this.chunk.charAt(0);
      }
      tag = value;
      prev = this.prev();
      if (prev && indexOf.call(['=', ...COMPOUND_ASSIGN], value) >= 0) {
        skipToken = false;
        if (value === '=' && ((ref = prev[1]) === '||' || ref === '&&') && !prev.spaced) {
          prev[0] = 'COMPOUND_ASSIGN';
          prev[1] += '=';
          prev = this.tokens[this.tokens.length - 2];
          skipToken = true;
        }
        if (prev && prev[0] !== 'PROPERTY') {
          origin = (ref1 = prev.origin) != null ? ref1 : prev;
          message = isUnassignable(prev[1], origin[1]);
          if (message) {
            this.error(message, origin[2]);
          }
        }
        if (skipToken) {
          return value.length;
        }
      }
      if (value === '{' && this.seenImport) {
        this.importSpecifierList = true;
      } else if (this.importSpecifierList && value === '}') {
        this.importSpecifierList = false;
      } else if (value === '{' && (prev != null ? prev[0] : void 0) === 'EXPORT') {
        this.exportSpecifierList = true;
      } else if (this.exportSpecifierList && value === '}') {
        this.exportSpecifierList = false;
      }
      if (value === ';') {
        this.seenFor = this.seenImport = this.seenExport = false;
        tag = 'TERMINATOR';
      } else if (value === '*' && prev[0] === 'EXPORT') {
        tag = 'EXPORT_ALL';
      } else if (indexOf.call(MATH, value) >= 0) {
        tag = 'MATH';
      } else if (indexOf.call(COMPARE, value) >= 0) {
        tag = 'COMPARE';
      } else if (indexOf.call(COMPOUND_ASSIGN, value) >= 0) {
        tag = 'COMPOUND_ASSIGN';
      } else if (indexOf.call(UNARY, value) >= 0) {
        tag = 'UNARY';
      } else if (indexOf.call(UNARY_MATH, value) >= 0) {
        tag = 'UNARY_MATH';
      } else if (indexOf.call(SHIFT, value) >= 0) {
        tag = 'SHIFT';
      } else if (value === '?' && (prev != null ? prev.spaced : void 0)) {
        tag = 'BIN?';
      } else if (prev && !prev.spaced) {
        if (value === '(' && (ref2 = prev[0], indexOf.call(CALLABLE, ref2) >= 0)) {
          if (prev[0] === '?') {
            prev[0] = 'FUNC_EXIST';
          }
          tag = 'CALL_START';
        } else if (value === '[' && (ref3 = prev[0], indexOf.call(INDEXABLE, ref3) >= 0)) {
          tag = 'INDEX_START';
          switch (prev[0]) {
            case '?':
              prev[0] = 'INDEX_SOAK';
          }
        }
      }
      token = this.makeToken(tag, value);
      switch (value) {
        case '(':
        case '{':
        case '[':
          this.ends.push({
            tag: INVERSES[value],
            origin: token
          });
          break;
        case ')':
        case '}':
        case ']':
          this.pair(value);
      }
      this.tokens.push(token);
      return value.length;
    }

    tagParameters() {
      var i, stack, tok, tokens;
      if (this.tag() !== ')') {
        return this;
      }
      stack = [];
      ({tokens} = this);
      i = tokens.length;
      tokens[--i][0] = 'PARAM_END';
      while (tok = tokens[--i]) {
        switch (tok[0]) {
          case ')':
            stack.push(tok);
            break;
          case '(':
          case 'CALL_START':
            if (stack.length) {
              stack.pop();
            } else if (tok[0] === '(') {
              tok[0] = 'PARAM_START';
              return this;
            } else {
              return this;
            }
        }
      }
      return this;
    }

    closeIndentation() {
      return this.outdentToken(this.indent);
    }

    matchWithInterpolations(regex, delimiter) {
      var close, column, firstToken, index, lastToken, line, nested, offsetInChunk, open, ref, str, strPart, tokens;
      tokens = [];
      offsetInChunk = delimiter.length;
      if (this.chunk.slice(0, offsetInChunk) !== delimiter) {
        return null;
      }
      str = this.chunk.slice(offsetInChunk);
      while (true) {
        [strPart] = regex.exec(str);
        this.validateEscapes(strPart, {
          isRegex: delimiter.charAt(0) === '/',
          offsetInChunk
        });
        tokens.push(this.makeToken('NEOSTRING', strPart, offsetInChunk));
        str = str.slice(strPart.length);
        offsetInChunk += strPart.length;
        if (str.slice(0, 2) !== '#{') {
          break;
        }
        [line, column] = this.getLineAndColumnFromChunk(offsetInChunk + 1);
        ({
          tokens: nested,
          index
        } = new Lexer().tokenize(str.slice(1), {
          line: line,
          column: column,
          untilBalanced: true
        }));
        index += 1;
        open = nested[0], close = nested[nested.length - 1];
        open[0] = open[1] = '(';
        close[0] = close[1] = ')';
        close.origin = ['', 'end of interpolation', close[2]];
        if (((ref = nested[1]) != null ? ref[0] : void 0) === 'TERMINATOR') {
          nested.splice(1, 1);
        }
        tokens.push(['TOKENS', nested]);
        str = str.slice(index);
        offsetInChunk += index;
      }
      if (str.slice(0, delimiter.length) !== delimiter) {
        this.error(`missing ${delimiter}`, {
          length: delimiter.length
        });
      }
      firstToken = tokens[0], lastToken = tokens[tokens.length - 1];
      firstToken[2].first_column -= delimiter.length;
      if (lastToken[1].substr(-1) === '\n') {
        lastToken[2].last_line += 1;
        lastToken[2].last_column = delimiter.length - 1;
      } else {
        lastToken[2].last_column += delimiter.length;
      }
      if (lastToken[1].length === 0) {
        lastToken[2].last_column -= 1;
      }
      return {
        tokens,
        index: offsetInChunk + delimiter.length
      };
    }

    mergeInterpolationTokens(tokens, options, fn) {
      var converted, firstEmptyStringIndex, firstIndex, i, j, lastToken, len, locationToken, lparen, plusToken, rparen, tag, token, tokensToPush, value;
      if (tokens.length > 1) {
        lparen = this.token('STRING_START', '(', 0, 0);
      }
      firstIndex = this.tokens.length;
      for (i = j = 0, len = tokens.length; j < len; i = ++j) {
        token = tokens[i];
        [tag, value] = token;
        switch (tag) {
          case 'TOKENS':
            if (value.length === 2) {
              continue;
            }
            locationToken = value[0];
            tokensToPush = value;
            break;
          case 'NEOSTRING':
            converted = fn(token[1], i);
            if (converted.length === 0) {
              if (i === 0) {
                firstEmptyStringIndex = this.tokens.length;
              } else {
                continue;
              }
            }
            if (i === 2 && (firstEmptyStringIndex != null)) {
              this.tokens.splice(firstEmptyStringIndex, 2);
            }
            token[0] = 'STRING';
            token[1] = this.makeDelimitedLiteral(converted, options);
            locationToken = token;
            tokensToPush = [token];
        }
        if (this.tokens.length > firstIndex) {
          plusToken = this.token('+', '+');
          plusToken[2] = {
            first_line: locationToken[2].first_line,
            first_column: locationToken[2].first_column,
            last_line: locationToken[2].first_line,
            last_column: locationToken[2].first_column
          };
        }
        this.tokens.push(...tokensToPush);
      }
      if (lparen) {
        lastToken = tokens[tokens.length - 1];
        lparen.origin = [
          'STRING', null, {
            first_line: lparen[2].first_line,
            first_column: lparen[2].first_column,
            last_line: lastToken[2].last_line,
            last_column: lastToken[2].last_column
          }
        ];
        rparen = this.token('STRING_END', ')');
        return rparen[2] = {
          first_line: lastToken[2].last_line,
          first_column: lastToken[2].last_column,
          last_line: lastToken[2].last_line,
          last_column: lastToken[2].last_column
        };
      }
    }

    pair(tag) {
      var lastIndent, prev, ref, ref1, wanted;
      ref = this.ends, prev = ref[ref.length - 1];
      if (tag !== (wanted = prev != null ? prev.tag : void 0)) {
        if ('OUTDENT' !== wanted) {
          this.error(`unmatched ${tag}`);
        }
        ref1 = this.indents, lastIndent = ref1[ref1.length - 1];
        this.outdentToken(lastIndent, true);
        return this.pair(tag);
      }
      return this.ends.pop();
    }

    getLineAndColumnFromChunk(offset) {
      var column, lastLine, lineCount, ref, string;
      if (offset === 0) {
        return [this.chunkLine, this.chunkColumn];
      }
      if (offset >= this.chunk.length) {
        string = this.chunk;
      } else {
        string = this.chunk.slice(0, +(offset - 1) + 1 || 9e9);
      }
      lineCount = count(string, '\n');
      column = this.chunkColumn;
      if (lineCount > 0) {
        ref = string.split('\n'), lastLine = ref[ref.length - 1];
        column = lastLine.length;
      } else {
        column += string.length;
      }
      return [this.chunkLine + lineCount, column];
    }

    makeToken(tag, value, offsetInChunk = 0, length = value.length) {
      var lastCharacter, locationData, token;
      locationData = {};
      [locationData.first_line, locationData.first_column] = this.getLineAndColumnFromChunk(offsetInChunk);
      lastCharacter = length > 0 ? length - 1 : 0;
      [locationData.last_line, locationData.last_column] = this.getLineAndColumnFromChunk(offsetInChunk + lastCharacter);
      token = [tag, value, locationData];
      return token;
    }

    token(tag, value, offsetInChunk, length, origin) {
      var token;
      token = this.makeToken(tag, value, offsetInChunk, length);
      if (origin) {
        token.origin = origin;
      }
      this.tokens.push(token);
      return token;
    }

    tag() {
      var ref, token;
      ref = this.tokens, token = ref[ref.length - 1];
      return token != null ? token[0] : void 0;
    }

    value() {
      var ref, token;
      ref = this.tokens, token = ref[ref.length - 1];
      return token != null ? token[1] : void 0;
    }

    prev() {
      return this.tokens[this.tokens.length - 1];
    }

    unfinished() {
      var ref;
      return LINE_CONTINUER.test(this.chunk) || ((ref = this.tag()) === '\\' || ref === '.' || ref === '?.' || ref === '?::' || ref === 'UNARY' || ref === 'MATH' || ref === 'UNARY_MATH' || ref === '+' || ref === '-' || ref === '**' || ref === 'SHIFT' || ref === 'RELATION' || ref === 'COMPARE' || ref === '&' || ref === '^' || ref === '|' || ref === '&&' || ref === '||' || ref === 'BIN?' || ref === 'THROW' || ref === 'EXTENDS');
    }

    formatString(str) {
      return str.replace(STRING_OMIT, '$1');
    }

    formatHeregex(str) {
      return str.replace(HEREGEX_OMIT, '$1$2');
    }

    validateEscapes(str, options = {}) {
      var before, hex, invalidEscape, invalidEscapeRegex, match, message, octal, ref, unicode;
      invalidEscapeRegex = options.isRegex ? REGEX_INVALID_ESCAPE : STRING_INVALID_ESCAPE;
      match = invalidEscapeRegex.exec(str);
      if (!match) {
        return;
      }
      match[0], before = match[1], octal = match[2], hex = match[3], unicode = match[4];
      message = octal ? "octal escape sequences are not allowed" : "invalid escape sequence";
      invalidEscape = `\\${octal || hex || unicode}`;
      return this.error(`${message} ${invalidEscape}`, {
        offset: ((ref = options.offsetInChunk) != null ? ref : 0) + match.index + before.length,
        length: invalidEscape.length
      });
    }

    makeDelimitedLiteral(body, options = {}) {
      var regex;
      if (body === '' && options.delimiter === '/') {
        body = '(?:)';
      }
      regex = RegExp(`(\\\\\\\\)|(\\\\0(?=[1-7]))|\\\\?(${options.delimiter})|\\\\?(?:(\\n)|(\\r)|(\\u2028)|(\\u2029))|(\\\\.)`, "g");
      body = body.replace(regex, function(match, backslash, nul, delimiter, lf, cr, ls, ps, other) {
        switch (false) {
          case !backslash:
            if (options.double) {
              return backslash + backslash;
            } else {
              return backslash;
            }
          case !nul:
            return '\\x00';
          case !delimiter:
            return `\\${delimiter}`;
          case !lf:
            return '\\n';
          case !cr:
            return '\\r';
          case !ls:
            return '\\u2028';
          case !ps:
            return '\\u2029';
          case !other:
            if (options.double) {
              return `\\${other}`;
            } else {
              return other;
            }
        }
      });
      return `${options.delimiter}${body}${options.delimiter}`;
    }

    error(message, options = {}) {
      var first_column, first_line, location, ref, ref1;
      location = 'first_line' in options ? options : ([first_line, first_column] = this.getLineAndColumnFromChunk((ref = options.offset) != null ? ref : 0), {
        first_line,
        first_column,
        last_column: first_column + ((ref1 = options.length) != null ? ref1 : 1) - 1
      });
      return throwSyntaxError(message, location);
    }

  };

  isUnassignable = function(name, displayName = name) {
    switch (false) {
      case indexOf.call([...JS_KEYWORDS, ...COFFEE_KEYWORDS], name) < 0:
        return `keyword '${displayName}' can't be assigned`;
      case indexOf.call(STRICT_PROSCRIBED, name) < 0:
        return `'${displayName}' can't be assigned`;
      case indexOf.call(RESERVED, name) < 0:
        return `reserved word '${displayName}' can't be assigned`;
      default:
        return false;
    }
  };

  exports.isUnassignable = isUnassignable;

  isForFrom = function(prev) {
    var ref;
    if (prev[0] === 'IDENTIFIER') {
      if (prev[1] === 'from') {
        prev[1][0] = 'IDENTIFIER';
        true;
      }
      return true;
    } else if (prev[0] === 'FOR') {
      return false;
    } else if ((ref = prev[1]) === '{' || ref === '[' || ref === ',' || ref === ':') {
      return false;
    } else {
      return true;
    }
  };

  JS_KEYWORDS = ['true', 'false', 'null', 'this', 'new', 'delete', 'typeof', 'in', 'instanceof', 'return', 'throw', 'break', 'continue', 'debugger', 'yield', 'await', 'if', 'else', 'switch', 'for', 'while', 'do', 'try', 'catch', 'finally', 'class', 'extends', 'super', 'import', 'export', 'default'];

  COFFEE_KEYWORDS = ['undefined', 'Infinity', 'NaN', 'then', 'unless', 'until', 'loop', 'of', 'by', 'when'];

  COFFEE_ALIAS_MAP = {
    and: '&&',
    or: '||',
    is: '==',
    isnt: '!=',
    not: '!',
    yes: 'true',
    no: 'false',
    on: 'true',
    off: 'false'
  };

  COFFEE_ALIASES = (function() {
    var results;
    results = [];
    for (key in COFFEE_ALIAS_MAP) {
      results.push(key);
    }
    return results;
  })();

  COFFEE_KEYWORDS = COFFEE_KEYWORDS.concat(COFFEE_ALIASES);

  RESERVED = ['case', 'function', 'var', 'void', 'with', 'const', 'let', 'enum', 'native', 'implements', 'interface', 'package', 'private', 'protected', 'public', 'static'];

  STRICT_PROSCRIBED = ['arguments', 'eval'];

  exports.JS_FORBIDDEN = JS_KEYWORDS.concat(RESERVED).concat(STRICT_PROSCRIBED);

  BOM = 65279;

  IDENTIFIER = /^(?!\d)((?:(?!\s)[$\w\x7f-\uffff])+)([^\n\S]*:(?!:))?/;

  NUMBER = /^0b[01]+|^0o[0-7]+|^0x[\da-f]+|^\d*\.?\d+(?:e[+-]?\d+)?/i;

  OPERATOR = /^(?:[-=]>|[-+*\/%<>&|^!?=]=|>>>=?|([-+:])\1|([&|<>*\/%])\2=?|\?(\.|::)|\.{2,3})/;

  WHITESPACE = /^[^\n\S]+/;

  COMMENT = /^###([^#][\s\S]*?)(?:###[^\n\S]*|###$)|^(?:\s*#(?!##[^#]).*)+/;

  CODE = /^[-=]>/;

  MULTI_DENT = /^(?:\n[^\n\S]*)+/;

  JSTOKEN = /^`(?!``)((?:[^`\\]|\\[\s\S])*)`/;

  HERE_JSTOKEN = /^```((?:[^`\\]|\\[\s\S]|`(?!``))*)```/;

  STRING_START = /^(?:'''|"""|'|")/;

  STRING_SINGLE = /^(?:[^\\']|\\[\s\S])*/;

  STRING_DOUBLE = /^(?:[^\\"#]|\\[\s\S]|\#(?!\{))*/;

  HEREDOC_SINGLE = /^(?:[^\\']|\\[\s\S]|'(?!''))*/;

  HEREDOC_DOUBLE = /^(?:[^\\"#]|\\[\s\S]|"(?!"")|\#(?!\{))*/;

  STRING_OMIT = /((?:\\\\)+)|\\[^\S\n]*\n\s*/g;

  SIMPLE_STRING_OMIT = /\s*\n\s*/g;

  HEREDOC_INDENT = /\n+([^\n\S]*)(?=\S)/g;

  REGEX = /^\/(?!\/)((?:[^[\/\n\\]|\\[^\n]|\[(?:\\[^\n]|[^\]\n\\])*\])*)(\/)?/;

  REGEX_FLAGS = /^\w*/;

  VALID_FLAGS = /^(?!.*(.).*\1)[imgy]*$/;

  HEREGEX = /^(?:[^\\\/#]|\\[\s\S]|\/(?!\/\/)|\#(?!\{))*/;

  HEREGEX_OMIT = /((?:\\\\)+)|\\(\s)|\s+(?:#.*)?/g;

  REGEX_ILLEGAL = /^(\/|\/{3}\s*)(\*)/;

  POSSIBLY_DIVISION = /^\/=?\s/;

  HERECOMMENT_ILLEGAL = /\*\//;

  LINE_CONTINUER = /^\s*(?:,|\??\.(?![.\d])|::)/;

  STRING_INVALID_ESCAPE = /((?:^|[^\\])(?:\\\\)*)\\(?:(0[0-7]|[1-7])|(x(?![\da-fA-F]{2}).{0,2})|(u(?![\da-fA-F]{4}).{0,4}))/;

  REGEX_INVALID_ESCAPE = /((?:^|[^\\])(?:\\\\)*)\\(?:(0[0-7])|(x(?![\da-fA-F]{2}).{0,2})|(u(?![\da-fA-F]{4}).{0,4}))/;

  LEADING_BLANK_LINE = /^[^\n\S]*\n/;

  TRAILING_BLANK_LINE = /\n[^\n\S]*$/;

  TRAILING_SPACES = /\s+$/;

  COMPOUND_ASSIGN = ['-=', '+=', '/=', '*=', '%=', '||=', '&&=', '?=', '<<=', '>>=', '>>>=', '&=', '^=', '|=', '**=', '//=', '%%='];

  UNARY = ['NEW', 'TYPEOF', 'DELETE', 'DO'];

  UNARY_MATH = ['!', '~'];

  SHIFT = ['<<', '>>', '>>>'];

  COMPARE = ['==', '!=', '<', '>', '<=', '>='];

  MATH = ['*', '/', '%', '//', '%%'];

  RELATION = ['IN', 'OF', 'INSTANCEOF'];

  BOOL = ['TRUE', 'FALSE'];

  CALLABLE = ['IDENTIFIER', 'PROPERTY', ')', ']', '?', '@', 'THIS', 'SUPER'];

  INDEXABLE = CALLABLE.concat(['NUMBER', 'INFINITY', 'NAN', 'STRING', 'STRING_END', 'REGEX', 'REGEX_END', 'BOOL', 'NULL', 'UNDEFINED', '}', '::']);

  NOT_REGEX = INDEXABLE.concat(['++', '--']);

  LINE_BREAK = ['INDENT', 'OUTDENT', 'TERMINATOR'];

  INDENTABLE_CLOSERS = [')', '}', ']'];

}).call(this);

  return module.exports;
})();require['./parser'] = (function() {
  var exports = {}, module = {exports: exports};
  /* parser generated by jison 0.4.17 */
/*
  Returns a Parser object of the following structure:

  Parser: {
    yy: {}
  }

  Parser.prototype: {
    yy: {},
    trace: function(),
    symbols_: {associative list: name ==> number},
    terminals_: {associative list: number ==> name},
    productions_: [...],
    performAction: function anonymous(yytext, yyleng, yylineno, yy, yystate, $$, _$),
    table: [...],
    defaultActions: {...},
    parseError: function(str, hash),
    parse: function(input),

    lexer: {
        EOF: 1,
        parseError: function(str, hash),
        setInput: function(input),
        input: function(),
        unput: function(str),
        more: function(),
        less: function(n),
        pastInput: function(),
        upcomingInput: function(),
        showPosition: function(),
        test_match: function(regex_match_array, rule_index),
        next: function(),
        lex: function(),
        begin: function(condition),
        popState: function(),
        _currentRules: function(),
        topState: function(),
        pushState: function(condition),

        options: {
            ranges: boolean           (optional: true ==> token location info will include a .range[] member)
            flex: boolean             (optional: true ==> flex-like lexing behaviour where the rules are tested exhaustively to find the longest match)
            backtrack_lexer: boolean  (optional: true ==> lexer regexes are tested in order and for each matching regex the action code is invoked; the lexer terminates the scan when a token is returned by the action code)
        },

        performAction: function(yy, yy_, $avoiding_name_collisions, YY_START),
        rules: [...],
        conditions: {associative list: name ==> set},
    }
  }


  token location info (@$, _$, etc.): {
    first_line: n,
    last_line: n,
    first_column: n,
    last_column: n,
    range: [start_number, end_number]       (where the numbers are indexes into the input string, regular zero-based)
  }


  the parseError function receives a 'hash' object with these members for lexer and parser errors: {
    text:        (matched text)
    token:       (the produced terminal token, if any)
    line:        (yylineno)
  }
  while parser (grammar) errors will also provide these members, i.e. parser errors deliver a superset of attributes: {
    loc:         (yylloc)
    expected:    (string describing the set of expected tokens)
    recoverable: (boolean: TRUE when the parser has a error recovery rule available for this particular error)
  }
*/
var parser = (function(){
var o=function(k,v,o,l){for(o=o||{},l=k.length;l--;o[k[l]]=v);return o},$V0=[1,22],$V1=[1,52],$V2=[1,86],$V3=[1,82],$V4=[1,87],$V5=[1,88],$V6=[1,84],$V7=[1,85],$V8=[1,60],$V9=[1,62],$Va=[1,63],$Vb=[1,64],$Vc=[1,65],$Vd=[1,66],$Ve=[1,53],$Vf=[1,40],$Vg=[1,54],$Vh=[1,34],$Vi=[1,71],$Vj=[1,72],$Vk=[1,33],$Vl=[1,81],$Vm=[1,50],$Vn=[1,55],$Vo=[1,56],$Vp=[1,69],$Vq=[1,70],$Vr=[1,68],$Vs=[1,45],$Vt=[1,51],$Vu=[1,67],$Vv=[1,76],$Vw=[1,77],$Vx=[1,78],$Vy=[1,79],$Vz=[1,49],$VA=[1,75],$VB=[1,36],$VC=[1,37],$VD=[1,38],$VE=[1,39],$VF=[1,41],$VG=[1,42],$VH=[1,89],$VI=[1,6,34,44,134],$VJ=[1,104],$VK=[1,92],$VL=[1,91],$VM=[1,90],$VN=[1,93],$VO=[1,94],$VP=[1,95],$VQ=[1,96],$VR=[1,97],$VS=[1,98],$VT=[1,99],$VU=[1,100],$VV=[1,101],$VW=[1,102],$VX=[1,103],$VY=[1,107],$VZ=[1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],$V_=[2,171],$V$=[1,113],$V01=[1,118],$V11=[1,114],$V21=[1,115],$V31=[1,116],$V41=[1,119],$V51=[1,112],$V61=[1,6,34,44,134,136,138,142,159],$V71=[1,6,33,34,42,43,44,68,73,76,87,88,89,90,91,92,95,99,116,117,118,123,125,134,136,137,138,142,143,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],$V81=[2,98],$V91=[2,77],$Va1=[1,129],$Vb1=[1,134],$Vc1=[1,135],$Vd1=[1,137],$Ve1=[1,141],$Vf1=[1,139],$Vg1=[1,6,33,34,42,43,44,57,68,73,76,87,88,89,90,91,92,95,99,116,117,118,123,125,134,136,137,138,142,143,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],$Vh1=[2,95],$Vi1=[1,6,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],$Vj1=[2,29],$Vk1=[1,167],$Vl1=[2,65],$Vm1=[1,175],$Vn1=[1,187],$Vo1=[1,189],$Vp1=[1,184],$Vq1=[1,191],$Vr1=[1,6,33,34,42,43,44,57,68,73,76,87,88,89,90,91,92,95,99,101,116,117,118,123,125,134,136,137,138,142,143,159,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178],$Vs1=[2,117],$Vt1=[1,6,33,34,42,43,44,60,68,73,76,87,88,89,90,91,92,95,99,116,117,118,123,125,134,136,137,138,142,143,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],$Vu1=[1,6,33,34,42,43,44,48,60,68,73,76,87,88,89,90,91,92,95,99,116,117,118,123,125,134,136,137,138,142,143,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],$Vv1=[1,239],$Vw1=[42,43,117],$Vx1=[1,249],$Vy1=[1,248],$Vz1=[2,75],$VA1=[1,259],$VB1=[6,33,34,68,73],$VC1=[6,33,34,57,68,73,76],$VD1=[1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,162,163,167,168,169,170,171,172,173,174,175,176,177],$VE1=[1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,162,163,167,169,170,171,172,173,174,175,176,177],$VF1=[42,43,87,88,90,91,92,95,116,117],$VG1=[1,279],$VH1=[1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159],$VI1=[2,64],$VJ1=[1,291],$VK1=[1,293],$VL1=[1,298],$VM1=[1,300],$VN1=[2,192],$VO1=[1,6,33,34,42,43,44,57,68,73,76,87,88,89,90,91,92,95,99,116,117,118,123,125,134,136,137,138,142,143,149,150,151,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],$VP1=[1,309],$VQ1=[6,33,34,73,118,123],$VR1=[1,6,33,34,42,43,44,57,60,68,73,76,87,88,89,90,91,92,95,99,101,116,117,118,123,125,134,136,137,138,142,143,149,150,151,159,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178],$VS1=[1,6,33,34,44,68,73,76,89,99,118,123,125,134,143,159],$VT1=[1,6,33,34,44,68,73,76,89,99,118,123,125,134,137,143,159],$VU1=[149,150,151],$VV1=[73,149,150,151],$VW1=[6,33,99],$VX1=[1,321],$VY1=[6,33,34,73,99],$VZ1=[6,33,34,60,73,99],$V_1=[6,33,34,57,60,73,99],$V$1=[1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,162,163,169,170,171,172,173,174,175,176,177],$V02=[1,6,33,34,44,48,68,73,76,87,88,89,90,91,92,95,99,116,117,118,123,125,134,136,137,138,142,143,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],$V12=[14,30,36,40,42,43,46,47,50,51,52,53,54,55,63,64,65,66,70,71,86,89,97,100,102,110,120,121,122,128,132,133,136,138,140,142,152,158,160,161,162,163,164,165],$V22=[2,181],$V32=[6,33,34],$V42=[2,76],$V52=[1,336],$V62=[1,337],$V72=[1,6,33,34,44,68,73,76,89,99,118,123,125,130,131,134,136,137,138,142,143,154,156,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],$V82=[34,154,156],$V92=[1,6,34,44,68,73,76,89,99,118,123,125,134,137,143,159],$Va2=[1,363],$Vb2=[1,369],$Vc2=[1,6,34,44,134,159],$Vd2=[2,90],$Ve2=[1,380],$Vf2=[1,381],$Vg2=[1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,154,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],$Vh2=[1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,138,142,143,159],$Vi2=[1,393],$Vj2=[1,394],$Vk2=[6,33,34,99],$Vl2=[6,33,34,73],$Vm2=[1,6,33,34,44,68,73,76,89,99,118,123,125,130,134,136,137,138,142,143,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],$Vn2=[33,73],$Vo2=[1,421],$Vp2=[1,422],$Vq2=[1,428],$Vr2=[1,429];
var parser = {trace: function trace() { },
yy: {},
symbols_: {"error":2,"Root":3,"Body":4,"Line":5,"TERMINATOR":6,"Expression":7,"Statement":8,"FuncDirective":9,"YieldReturn":10,"AwaitReturn":11,"Return":12,"Comment":13,"STATEMENT":14,"Import":15,"Export":16,"Value":17,"Invocation":18,"Code":19,"Operation":20,"Assign":21,"If":22,"Try":23,"While":24,"For":25,"Switch":26,"Class":27,"Throw":28,"Yield":29,"YIELD":30,"FROM":31,"Block":32,"INDENT":33,"OUTDENT":34,"Identifier":35,"IDENTIFIER":36,"Property":37,"PROPERTY":38,"AlphaNumeric":39,"NUMBER":40,"String":41,"STRING":42,"STRING_START":43,"STRING_END":44,"Regex":45,"REGEX":46,"REGEX_START":47,"REGEX_END":48,"Literal":49,"JS":50,"UNDEFINED":51,"NULL":52,"BOOL":53,"INFINITY":54,"NAN":55,"Assignable":56,"=":57,"AssignObj":58,"ObjAssignable":59,":":60,"SimpleObjAssignable":61,"ThisProperty":62,"RETURN":63,"AWAIT":64,"HERECOMMENT":65,"PARAM_START":66,"ParamList":67,"PARAM_END":68,"FuncGlyph":69,"->":70,"=>":71,"OptComma":72,",":73,"Param":74,"ParamVar":75,"...":76,"Array":77,"Object":78,"Splat":79,"SimpleAssignable":80,"Accessor":81,"Parenthetical":82,"Range":83,"This":84,"Super":85,"SUPER":86,".":87,"INDEX_START":88,"INDEX_END":89,"?.":90,"::":91,"?::":92,"Index":93,"IndexValue":94,"INDEX_SOAK":95,"Slice":96,"{":97,"AssignList":98,"}":99,"CLASS":100,"EXTENDS":101,"IMPORT":102,"ImportDefaultSpecifier":103,"ImportNamespaceSpecifier":104,"ImportSpecifierList":105,"ImportSpecifier":106,"AS":107,"DEFAULT":108,"IMPORT_ALL":109,"EXPORT":110,"ExportSpecifierList":111,"EXPORT_ALL":112,"ExportSpecifier":113,"OptFuncExist":114,"Arguments":115,"FUNC_EXIST":116,"CALL_START":117,"CALL_END":118,"ArgList":119,"THIS":120,"@":121,"[":122,"]":123,"RangeDots":124,"..":125,"Arg":126,"SimpleArgs":127,"TRY":128,"Catch":129,"FINALLY":130,"CATCH":131,"THROW":132,"(":133,")":134,"WhileSource":135,"WHILE":136,"WHEN":137,"UNTIL":138,"Loop":139,"LOOP":140,"ForBody":141,"FOR":142,"BY":143,"ForStart":144,"ForSource":145,"ForVariables":146,"OWN":147,"ForValue":148,"FORIN":149,"FOROF":150,"FORFROM":151,"SWITCH":152,"Whens":153,"ELSE":154,"When":155,"LEADING_WHEN":156,"IfBlock":157,"IF":158,"POST_IF":159,"UNARY":160,"UNARY_MATH":161,"-":162,"+":163,"--":164,"++":165,"?":166,"MATH":167,"**":168,"SHIFT":169,"COMPARE":170,"&":171,"^":172,"|":173,"&&":174,"||":175,"BIN?":176,"RELATION":177,"COMPOUND_ASSIGN":178,"$accept":0,"$end":1},
terminals_: {2:"error",6:"TERMINATOR",14:"STATEMENT",30:"YIELD",31:"FROM",33:"INDENT",34:"OUTDENT",36:"IDENTIFIER",38:"PROPERTY",40:"NUMBER",42:"STRING",43:"STRING_START",44:"STRING_END",46:"REGEX",47:"REGEX_START",48:"REGEX_END",50:"JS",51:"UNDEFINED",52:"NULL",53:"BOOL",54:"INFINITY",55:"NAN",57:"=",60:":",63:"RETURN",64:"AWAIT",65:"HERECOMMENT",66:"PARAM_START",68:"PARAM_END",70:"->",71:"=>",73:",",76:"...",86:"SUPER",87:".",88:"INDEX_START",89:"INDEX_END",90:"?.",91:"::",92:"?::",95:"INDEX_SOAK",97:"{",99:"}",100:"CLASS",101:"EXTENDS",102:"IMPORT",107:"AS",108:"DEFAULT",109:"IMPORT_ALL",110:"EXPORT",112:"EXPORT_ALL",116:"FUNC_EXIST",117:"CALL_START",118:"CALL_END",120:"THIS",121:"@",122:"[",123:"]",125:"..",128:"TRY",130:"FINALLY",131:"CATCH",132:"THROW",133:"(",134:")",136:"WHILE",137:"WHEN",138:"UNTIL",140:"LOOP",142:"FOR",143:"BY",147:"OWN",149:"FORIN",150:"FOROF",151:"FORFROM",152:"SWITCH",154:"ELSE",156:"LEADING_WHEN",158:"IF",159:"POST_IF",160:"UNARY",161:"UNARY_MATH",162:"-",163:"+",164:"--",165:"++",166:"?",167:"MATH",168:"**",169:"SHIFT",170:"COMPARE",171:"&",172:"^",173:"|",174:"&&",175:"||",176:"BIN?",177:"RELATION",178:"COMPOUND_ASSIGN"},
productions_: [0,[3,0],[3,1],[4,1],[4,3],[4,2],[5,1],[5,1],[5,1],[9,1],[9,1],[8,1],[8,1],[8,1],[8,1],[8,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[29,1],[29,2],[29,3],[32,2],[32,3],[35,1],[37,1],[39,1],[39,1],[41,1],[41,3],[45,1],[45,3],[49,1],[49,1],[49,1],[49,1],[49,1],[49,1],[49,1],[49,1],[21,3],[21,4],[21,5],[58,1],[58,3],[58,5],[58,3],[58,5],[58,1],[61,1],[61,1],[61,1],[59,1],[59,1],[12,2],[12,1],[10,3],[10,2],[11,3],[11,2],[13,1],[19,5],[19,2],[69,1],[69,1],[72,0],[72,1],[67,0],[67,1],[67,3],[67,4],[67,6],[74,1],[74,2],[74,3],[74,1],[75,1],[75,1],[75,1],[75,1],[79,2],[80,1],[80,2],[80,2],[80,1],[56,1],[56,1],[56,1],[17,1],[17,1],[17,1],[17,1],[17,1],[17,1],[85,3],[85,4],[81,2],[81,2],[81,2],[81,2],[81,1],[81,1],[93,3],[93,2],[94,1],[94,1],[78,4],[98,0],[98,1],[98,3],[98,4],[98,6],[27,1],[27,2],[27,3],[27,4],[27,2],[27,3],[27,4],[27,5],[15,2],[15,4],[15,4],[15,5],[15,7],[15,6],[15,9],[105,1],[105,3],[105,4],[105,4],[105,6],[106,1],[106,3],[106,1],[106,3],[103,1],[104,3],[16,3],[16,5],[16,2],[16,4],[16,5],[16,6],[16,3],[16,4],[16,7],[111,1],[111,3],[111,4],[111,4],[111,6],[113,1],[113,3],[113,3],[113,1],[113,3],[18,3],[18,3],[18,3],[18,3],[114,0],[114,1],[115,2],[115,4],[84,1],[84,1],[62,2],[77,2],[77,4],[124,1],[124,1],[83,5],[96,3],[96,2],[96,2],[96,1],[119,1],[119,3],[119,4],[119,4],[119,6],[126,1],[126,1],[126,1],[127,1],[127,3],[23,2],[23,3],[23,4],[23,5],[129,3],[129,3],[129,2],[28,2],[82,3],[82,5],[135,2],[135,4],[135,2],[135,4],[24,2],[24,2],[24,2],[24,1],[139,2],[139,2],[25,2],[25,2],[25,2],[141,2],[141,4],[141,2],[144,2],[144,3],[148,1],[148,1],[148,1],[148,1],[146,1],[146,3],[145,2],[145,2],[145,4],[145,4],[145,4],[145,6],[145,6],[145,2],[145,4],[26,5],[26,7],[26,4],[26,6],[153,1],[153,2],[155,3],[155,4],[157,3],[157,5],[22,1],[22,3],[22,3],[22,3],[20,2],[20,2],[20,2],[20,2],[20,2],[20,2],[20,2],[20,2],[20,2],[20,2],[20,3],[20,3],[20,3],[20,3],[20,3],[20,3],[20,3],[20,3],[20,3],[20,3],[20,3],[20,3],[20,3],[20,3],[20,5],[20,4],[20,3]],
performAction: function anonymous(yytext, yyleng, yylineno, yy, yystate /* action[1] */, $$ /* vstack */, _$ /* lstack */) {
/* this == yyval */

var $0 = $$.length - 1;
switch (yystate) {
case 1:
return this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Block);
break;
case 2:
return this.$ = $$[$0];
break;
case 3:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(yy.Block.wrap([$$[$0]]));
break;
case 4:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])($$[$0-2].push($$[$0]));
break;
case 5:
this.$ = $$[$0-1];
break;
case 6: case 7: case 8: case 9: case 10: case 11: case 12: case 14: case 15: case 16: case 17: case 18: case 19: case 20: case 21: case 22: case 23: case 24: case 25: case 26: case 27: case 28: case 37: case 42: case 44: case 58: case 59: case 60: case 61: case 62: case 63: case 75: case 76: case 86: case 87: case 88: case 89: case 94: case 95: case 98: case 102: case 103: case 111: case 192: case 193: case 195: case 225: case 226: case 244: case 250:
this.$ = $$[$0];
break;
case 13:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.StatementLiteral($$[$0]));
break;
case 29:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Op($$[$0], new yy.Value(new yy.Literal(''))));
break;
case 30: case 254: case 255: case 258:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Op($$[$0-1], $$[$0]));
break;
case 31:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Op($$[$0-2].concat($$[$0-1]), $$[$0]));
break;
case 32:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Block);
break;
case 33: case 112:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])($$[$0-1]);
break;
case 34:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.IdentifierLiteral($$[$0]));
break;
case 35:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.PropertyName($$[$0]));
break;
case 36:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.NumberLiteral($$[$0]));
break;
case 38:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.StringLiteral($$[$0]));
break;
case 39:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.StringWithInterpolations($$[$0-1]));
break;
case 40:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.RegexLiteral($$[$0]));
break;
case 41:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.RegexWithInterpolations($$[$0-1].args));
break;
case 43:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.PassthroughLiteral($$[$0]));
break;
case 45:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.UndefinedLiteral);
break;
case 46:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.NullLiteral);
break;
case 47:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.BooleanLiteral($$[$0]));
break;
case 48:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.InfinityLiteral($$[$0]));
break;
case 49:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.NaNLiteral);
break;
case 50:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Assign($$[$0-2], $$[$0]));
break;
case 51:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.Assign($$[$0-3], $$[$0]));
break;
case 52:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.Assign($$[$0-4], $$[$0-1]));
break;
case 53: case 91: case 96: case 97: case 99: case 100: case 101: case 227: case 228:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Value($$[$0]));
break;
case 54:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Assign(yy.addLocationDataFn(_$[$0-2])(new yy.Value($$[$0-2])), $$[$0], 'object', {
          operatorToken: yy.addLocationDataFn(_$[$0-1])(new yy.Literal($$[$0-1]))
        }));
break;
case 55:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.Assign(yy.addLocationDataFn(_$[$0-4])(new yy.Value($$[$0-4])), $$[$0-1], 'object', {
          operatorToken: yy.addLocationDataFn(_$[$0-3])(new yy.Literal($$[$0-3]))
        }));
break;
case 56:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Assign(yy.addLocationDataFn(_$[$0-2])(new yy.Value($$[$0-2])), $$[$0], null, {
          operatorToken: yy.addLocationDataFn(_$[$0-1])(new yy.Literal($$[$0-1]))
        }));
break;
case 57:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.Assign(yy.addLocationDataFn(_$[$0-4])(new yy.Value($$[$0-4])), $$[$0-1], null, {
          operatorToken: yy.addLocationDataFn(_$[$0-3])(new yy.Literal($$[$0-3]))
        }));
break;
case 64:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Return($$[$0]));
break;
case 65:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Return);
break;
case 66:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.YieldReturn($$[$0]));
break;
case 67:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.YieldReturn);
break;
case 68:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.AwaitReturn($$[$0]));
break;
case 69:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.AwaitReturn);
break;
case 70:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Comment($$[$0]));
break;
case 71:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.Code($$[$0-3], $$[$0], $$[$0-1]));
break;
case 72:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Code([], $$[$0], $$[$0-1]));
break;
case 73:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])('func');
break;
case 74:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])('boundfunc');
break;
case 77: case 117:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])([]);
break;
case 78: case 118: case 137: case 157: case 187: case 229:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])([$$[$0]]);
break;
case 79: case 119: case 138: case 158: case 188:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])($$[$0-2].concat($$[$0]));
break;
case 80: case 120: case 139: case 159: case 189:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])($$[$0-3].concat($$[$0]));
break;
case 81: case 121: case 141: case 161: case 191:
this.$ = yy.addLocationDataFn(_$[$0-5], _$[$0])($$[$0-5].concat($$[$0-2]));
break;
case 82:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Param($$[$0]));
break;
case 83:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Param($$[$0-1], null, true));
break;
case 84:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Param($$[$0-2], $$[$0]));
break;
case 85: case 194:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Expansion);
break;
case 90:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Splat($$[$0-1]));
break;
case 92:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])($$[$0-1].add($$[$0]));
break;
case 93:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Value($$[$0-1], [].concat($$[$0])));
break;
case 104:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Super(yy.addLocationDataFn(_$[$0])(new yy.Access($$[$0]))));
break;
case 105:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.Super(yy.addLocationDataFn(_$[$0-1])(new yy.Index($$[$0-1]))));
break;
case 106:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Access($$[$0]));
break;
case 107:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Access($$[$0], 'soak'));
break;
case 108:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])([yy.addLocationDataFn(_$[$0-1])(new yy.Access(new yy.PropertyName('prototype'))), yy.addLocationDataFn(_$[$0])(new yy.Access($$[$0]))]);
break;
case 109:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])([yy.addLocationDataFn(_$[$0-1])(new yy.Access(new yy.PropertyName('prototype'), 'soak')), yy.addLocationDataFn(_$[$0])(new yy.Access($$[$0]))]);
break;
case 110:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Access(new yy.PropertyName('prototype')));
break;
case 113:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(yy.extend($$[$0], {
          soak: true
        }));
break;
case 114:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Index($$[$0]));
break;
case 115:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Slice($$[$0]));
break;
case 116:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.Obj($$[$0-2], $$[$0-3].generated));
break;
case 122:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Class);
break;
case 123:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Class(null, null, $$[$0]));
break;
case 124:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Class(null, $$[$0]));
break;
case 125:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.Class(null, $$[$0-1], $$[$0]));
break;
case 126:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Class($$[$0]));
break;
case 127:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Class($$[$0-1], null, $$[$0]));
break;
case 128:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.Class($$[$0-2], $$[$0]));
break;
case 129:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.Class($$[$0-3], $$[$0-1], $$[$0]));
break;
case 130:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.ImportDeclaration(null, $$[$0]));
break;
case 131:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.ImportDeclaration(new yy.ImportClause($$[$0-2], null), $$[$0]));
break;
case 132:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.ImportDeclaration(new yy.ImportClause(null, $$[$0-2]), $$[$0]));
break;
case 133:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.ImportDeclaration(new yy.ImportClause(null, new yy.ImportSpecifierList([])), $$[$0]));
break;
case 134:
this.$ = yy.addLocationDataFn(_$[$0-6], _$[$0])(new yy.ImportDeclaration(new yy.ImportClause(null, new yy.ImportSpecifierList($$[$0-4])), $$[$0]));
break;
case 135:
this.$ = yy.addLocationDataFn(_$[$0-5], _$[$0])(new yy.ImportDeclaration(new yy.ImportClause($$[$0-4], $$[$0-2]), $$[$0]));
break;
case 136:
this.$ = yy.addLocationDataFn(_$[$0-8], _$[$0])(new yy.ImportDeclaration(new yy.ImportClause($$[$0-7], new yy.ImportSpecifierList($$[$0-4])), $$[$0]));
break;
case 140: case 160: case 174: case 190:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])($$[$0-2]);
break;
case 142:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.ImportSpecifier($$[$0]));
break;
case 143:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.ImportSpecifier($$[$0-2], $$[$0]));
break;
case 144:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.ImportSpecifier(new yy.Literal($$[$0])));
break;
case 145:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.ImportSpecifier(new yy.Literal($$[$0-2]), $$[$0]));
break;
case 146:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.ImportDefaultSpecifier($$[$0]));
break;
case 147:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.ImportNamespaceSpecifier(new yy.Literal($$[$0-2]), $$[$0]));
break;
case 148:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.ExportNamedDeclaration(new yy.ExportSpecifierList([])));
break;
case 149:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.ExportNamedDeclaration(new yy.ExportSpecifierList($$[$0-2])));
break;
case 150:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.ExportNamedDeclaration($$[$0]));
break;
case 151:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.ExportNamedDeclaration(new yy.Assign($$[$0-2], $$[$0], null, {
          moduleDeclaration: 'export'
        })));
break;
case 152:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.ExportNamedDeclaration(new yy.Assign($$[$0-3], $$[$0], null, {
          moduleDeclaration: 'export'
        })));
break;
case 153:
this.$ = yy.addLocationDataFn(_$[$0-5], _$[$0])(new yy.ExportNamedDeclaration(new yy.Assign($$[$0-4], $$[$0-1], null, {
          moduleDeclaration: 'export'
        })));
break;
case 154:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.ExportDefaultDeclaration($$[$0]));
break;
case 155:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.ExportAllDeclaration(new yy.Literal($$[$0-2]), $$[$0]));
break;
case 156:
this.$ = yy.addLocationDataFn(_$[$0-6], _$[$0])(new yy.ExportNamedDeclaration(new yy.ExportSpecifierList($$[$0-4]), $$[$0]));
break;
case 162:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.ExportSpecifier($$[$0]));
break;
case 163:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.ExportSpecifier($$[$0-2], $$[$0]));
break;
case 164:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.ExportSpecifier($$[$0-2], new yy.Literal($$[$0])));
break;
case 165:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.ExportSpecifier(new yy.Literal($$[$0])));
break;
case 166:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.ExportSpecifier(new yy.Literal($$[$0-2]), $$[$0]));
break;
case 167:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.TaggedTemplateCall($$[$0-2], $$[$0], $$[$0-1]));
break;
case 168: case 169:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Call($$[$0-2], $$[$0], $$[$0-1]));
break;
case 170:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.SuperCall(yy.addLocationDataFn(_$[$0-2])(new yy.Super), $$[$0], $$[$0-1]));
break;
case 171:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(false);
break;
case 172:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(true);
break;
case 173:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])([]);
break;
case 175: case 176:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Value(new yy.ThisLiteral));
break;
case 177:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Value(yy.addLocationDataFn(_$[$0-1])(new yy.ThisLiteral), [yy.addLocationDataFn(_$[$0])(new yy.Access($$[$0]))], 'this'));
break;
case 178:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Arr([]));
break;
case 179:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.Arr($$[$0-2]));
break;
case 180:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])('inclusive');
break;
case 181:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])('exclusive');
break;
case 182:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.Range($$[$0-3], $$[$0-1], $$[$0-2]));
break;
case 183:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Range($$[$0-2], $$[$0], $$[$0-1]));
break;
case 184:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Range($$[$0-1], null, $$[$0]));
break;
case 185:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Range(null, $$[$0], $$[$0-1]));
break;
case 186:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])(new yy.Range(null, null, $$[$0]));
break;
case 196:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])([].concat($$[$0-2], $$[$0]));
break;
case 197:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Try($$[$0]));
break;
case 198:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Try($$[$0-1], $$[$0][0], $$[$0][1]));
break;
case 199:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.Try($$[$0-2], null, null, $$[$0]));
break;
case 200:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.Try($$[$0-3], $$[$0-2][0], $$[$0-2][1], $$[$0]));
break;
case 201:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])([$$[$0-1], $$[$0]]);
break;
case 202:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])([yy.addLocationDataFn(_$[$0-1])(new yy.Value($$[$0-1])), $$[$0]]);
break;
case 203:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])([null, $$[$0]]);
break;
case 204:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Throw($$[$0]));
break;
case 205:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Parens($$[$0-1]));
break;
case 206:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.Parens($$[$0-2]));
break;
case 207:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.While($$[$0]));
break;
case 208:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.While($$[$0-2], {
          guard: $$[$0]
        }));
break;
case 209:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.While($$[$0], {
          invert: true
        }));
break;
case 210:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.While($$[$0-2], {
          invert: true,
          guard: $$[$0]
        }));
break;
case 211:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])($$[$0-1].addBody($$[$0]));
break;
case 212: case 213:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])($$[$0].addBody(yy.addLocationDataFn(_$[$0-1])(yy.Block.wrap([$$[$0-1]]))));
break;
case 214:
this.$ = yy.addLocationDataFn(_$[$0], _$[$0])($$[$0]);
break;
case 215:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.While(yy.addLocationDataFn(_$[$0-1])(new yy.BooleanLiteral('true'))).addBody($$[$0]));
break;
case 216:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.While(yy.addLocationDataFn(_$[$0-1])(new yy.BooleanLiteral('true'))).addBody(yy.addLocationDataFn(_$[$0])(yy.Block.wrap([$$[$0]]))));
break;
case 217: case 218:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.For($$[$0-1], $$[$0]));
break;
case 219:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.For($$[$0], $$[$0-1]));
break;
case 220:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])({
          source: yy.addLocationDataFn(_$[$0])(new yy.Value($$[$0]))
        });
break;
case 221:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])({
          source: yy.addLocationDataFn(_$[$0-2])(new yy.Value($$[$0-2])),
          step: $$[$0]
        });
break;
case 222:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])((function () {
        $$[$0].own = $$[$0-1].own;
        $$[$0].ownTag = $$[$0-1].ownTag;
        $$[$0].name = $$[$0-1][0];
        $$[$0].index = $$[$0-1][1];
        return $$[$0];
      }()));
break;
case 223:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])($$[$0]);
break;
case 224:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])((function () {
        $$[$0].own = true;
        $$[$0].ownTag = yy.addLocationDataFn(_$[$0-1])(new yy.Literal($$[$0-1]));
        return $$[$0];
      }()));
break;
case 230:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])([$$[$0-2], $$[$0]]);
break;
case 231:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])({
          source: $$[$0]
        });
break;
case 232:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])({
          source: $$[$0],
          object: true
        });
break;
case 233:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])({
          source: $$[$0-2],
          guard: $$[$0]
        });
break;
case 234:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])({
          source: $$[$0-2],
          guard: $$[$0],
          object: true
        });
break;
case 235:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])({
          source: $$[$0-2],
          step: $$[$0]
        });
break;
case 236:
this.$ = yy.addLocationDataFn(_$[$0-5], _$[$0])({
          source: $$[$0-4],
          guard: $$[$0-2],
          step: $$[$0]
        });
break;
case 237:
this.$ = yy.addLocationDataFn(_$[$0-5], _$[$0])({
          source: $$[$0-4],
          step: $$[$0-2],
          guard: $$[$0]
        });
break;
case 238:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])({
          source: $$[$0],
          from: true
        });
break;
case 239:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])({
          source: $$[$0-2],
          guard: $$[$0],
          from: true
        });
break;
case 240:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.Switch($$[$0-3], $$[$0-1]));
break;
case 241:
this.$ = yy.addLocationDataFn(_$[$0-6], _$[$0])(new yy.Switch($$[$0-5], $$[$0-3], $$[$0-1]));
break;
case 242:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.Switch(null, $$[$0-1]));
break;
case 243:
this.$ = yy.addLocationDataFn(_$[$0-5], _$[$0])(new yy.Switch(null, $$[$0-3], $$[$0-1]));
break;
case 245:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])($$[$0-1].concat($$[$0]));
break;
case 246:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])([[$$[$0-1], $$[$0]]]);
break;
case 247:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])([[$$[$0-2], $$[$0-1]]]);
break;
case 248:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.If($$[$0-1], $$[$0], {
          type: $$[$0-2]
        }));
break;
case 249:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])($$[$0-4].addElse(yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.If($$[$0-1], $$[$0], {
          type: $$[$0-2]
        }))));
break;
case 251:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])($$[$0-2].addElse($$[$0]));
break;
case 252: case 253:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.If($$[$0], yy.addLocationDataFn(_$[$0-2])(yy.Block.wrap([$$[$0-2]])), {
          type: $$[$0-1],
          statement: true
        }));
break;
case 256:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Op('-', $$[$0]));
break;
case 257:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Op('+', $$[$0]));
break;
case 259:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Op('--', $$[$0]));
break;
case 260:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Op('++', $$[$0]));
break;
case 261:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Op('--', $$[$0-1], null, true));
break;
case 262:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Op('++', $$[$0-1], null, true));
break;
case 263:
this.$ = yy.addLocationDataFn(_$[$0-1], _$[$0])(new yy.Existence($$[$0-1]));
break;
case 264:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Op('+', $$[$0-2], $$[$0]));
break;
case 265:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Op('-', $$[$0-2], $$[$0]));
break;
case 266: case 267: case 268: case 269: case 270: case 271: case 272: case 273: case 274: case 275:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Op($$[$0-1], $$[$0-2], $$[$0]));
break;
case 276:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])((function () {
        if ($$[$0-1].charAt(0) === '!') {
          return new yy.Op($$[$0-1].slice(1), $$[$0-2], $$[$0]).invert();
        } else {
          return new yy.Op($$[$0-1], $$[$0-2], $$[$0]);
        }
      }()));
break;
case 277:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Assign($$[$0-2], $$[$0], $$[$0-1]));
break;
case 278:
this.$ = yy.addLocationDataFn(_$[$0-4], _$[$0])(new yy.Assign($$[$0-4], $$[$0-1], $$[$0-3]));
break;
case 279:
this.$ = yy.addLocationDataFn(_$[$0-3], _$[$0])(new yy.Assign($$[$0-3], $$[$0], $$[$0-2]));
break;
case 280:
this.$ = yy.addLocationDataFn(_$[$0-2], _$[$0])(new yy.Extends($$[$0-2], $$[$0]));
break;
}
},
table: [{1:[2,1],3:1,4:2,5:3,7:4,8:5,9:6,10:25,11:26,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$V1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{1:[3]},{1:[2,2],6:$VH},o($VI,[2,3]),o($VI,[2,6],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VI,[2,7],{144:80,135:108,141:109,136:$Vv,138:$Vw,142:$Vy,159:$VY}),o($VI,[2,8]),o($VZ,[2,16],{114:110,81:111,93:117,42:$V_,43:$V_,117:$V_,87:$V$,88:$V01,90:$V11,91:$V21,92:$V31,95:$V41,116:$V51}),o($VZ,[2,17],{93:117,114:120,81:121,87:$V$,88:$V01,90:$V11,91:$V21,92:$V31,95:$V41,116:$V51,117:$V_}),o($VZ,[2,18]),o($VZ,[2,19]),o($VZ,[2,20]),o($VZ,[2,21]),o($VZ,[2,22]),o($VZ,[2,23]),o($VZ,[2,24]),o($VZ,[2,25]),o($VZ,[2,26]),o($VZ,[2,27]),o($VZ,[2,28]),o($V61,[2,11]),o($V61,[2,12]),o($V61,[2,13]),o($V61,[2,14]),o($V61,[2,15]),o($VI,[2,9]),o($VI,[2,10]),o($V71,$V81,{57:[1,122]}),o($V71,[2,99]),o($V71,[2,100]),o($V71,[2,101]),o($V71,[2,102]),o($V71,[2,103]),{87:[1,124],88:[1,125],114:123,116:$V51,117:$V_},o([6,33,68,73],$V91,{67:126,74:127,75:128,35:130,62:131,77:132,78:133,36:$V2,76:$Va1,97:$Vl,121:$Vb1,122:$Vc1}),{32:136,33:$Vd1},{7:138,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:142,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:143,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:144,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:145,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:[1,146],64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{17:148,18:149,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:150,62:74,77:57,78:58,80:147,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,120:$Vp,121:$Vq,122:$Vr,133:$Vu},{17:148,18:149,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:150,62:74,77:57,78:58,80:151,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,120:$Vp,121:$Vq,122:$Vr,133:$Vu},o($Vg1,$Vh1,{101:[1,155],164:[1,152],165:[1,153],178:[1,154]}),o($VZ,[2,250],{154:[1,156]}),{32:157,33:$Vd1},{32:158,33:$Vd1},o($VZ,[2,214]),{32:159,33:$Vd1},{7:160,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,33:[1,161],35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($Vi1,[2,122],{49:28,82:29,83:30,84:31,85:32,77:57,78:58,39:59,45:61,35:73,62:74,41:83,17:148,18:149,56:150,32:162,80:164,33:$Vd1,36:$V2,40:$V3,42:$V4,43:$V5,46:$V6,47:$V7,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,86:$Vk,97:$Vl,101:[1,163],120:$Vp,121:$Vq,122:$Vr,133:$Vu}),{7:165,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o([1,6,34,44,134,136,138,142,159,166,167,168,169,170,171,172,173,174,175,176,177],$Vj1,{17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,12:20,13:21,15:23,16:24,56:27,49:28,82:29,83:30,84:31,85:32,69:35,80:43,157:44,135:46,139:47,141:48,77:57,78:58,39:59,45:61,35:73,62:74,144:80,41:83,8:140,7:166,14:$V0,30:$Ve1,31:$Vk1,36:$V2,40:$V3,42:$V4,43:$V5,46:$V6,47:$V7,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,63:[1,168],64:$Vf1,65:$Vg,66:$Vh,70:$Vi,71:$Vj,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,140:$Vx,152:$Vz,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG}),o($V61,$Vl1,{17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,12:20,13:21,15:23,16:24,56:27,49:28,82:29,83:30,84:31,85:32,69:35,80:43,157:44,135:46,139:47,141:48,77:57,78:58,39:59,45:61,35:73,62:74,144:80,41:83,8:140,7:169,14:$V0,30:$Ve1,36:$V2,40:$V3,42:$V4,43:$V5,46:$V6,47:$V7,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,70:$Vi,71:$Vj,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,140:$Vx,152:$Vz,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG}),o([1,6,33,34,44,73,99,134,136,138,142,159],[2,70]),{35:174,36:$V2,41:170,42:$V4,43:$V5,97:[1,173],103:171,104:172,109:$Vm1},{27:177,35:178,36:$V2,97:[1,176],100:$Vm,108:[1,179],112:[1,180]},o($Vg1,[2,96]),o($Vg1,[2,97]),o($V71,[2,42]),o($V71,[2,43]),o($V71,[2,44]),o($V71,[2,45]),o($V71,[2,46]),o($V71,[2,47]),o($V71,[2,48]),o($V71,[2,49]),{4:181,5:3,7:4,8:5,9:6,10:25,11:26,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$V1,33:[1,182],35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:183,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,33:$Vn1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,76:$Vo1,77:57,78:58,79:188,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,119:185,120:$Vp,121:$Vq,122:$Vr,123:$Vp1,126:186,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($V71,[2,175]),o($V71,[2,176],{37:190,38:$Vq1}),{33:[2,73]},{33:[2,74]},o($Vr1,[2,91]),o($Vr1,[2,94]),{7:192,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:193,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:194,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:196,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,32:195,33:$Vd1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{35:201,36:$V2,62:202,77:203,78:204,83:197,97:$Vl,121:$Vb1,122:$Vr,146:198,147:[1,199],148:200},{145:205,149:[1,206],150:[1,207],151:[1,208]},o([6,33,73,99],$Vs1,{41:83,98:209,58:210,59:211,61:212,13:213,39:214,35:215,37:216,62:217,36:$V2,38:$Vq1,40:$V3,42:$V4,43:$V5,65:$Vg,121:$Vb1}),o($Vt1,[2,36]),o($Vt1,[2,37]),o($V71,[2,40]),{17:148,18:218,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:150,62:74,77:57,78:58,80:219,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,120:$Vp,121:$Vq,122:$Vr,133:$Vu},o([1,6,31,33,34,42,43,44,57,60,68,73,76,87,88,89,90,91,92,95,99,101,107,116,117,118,123,125,134,136,137,138,142,143,149,150,151,159,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178],[2,34]),o($Vu1,[2,38]),{4:220,5:3,7:4,8:5,9:6,10:25,11:26,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$V1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VI,[2,5],{7:4,8:5,9:6,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,12:20,13:21,15:23,16:24,10:25,11:26,56:27,49:28,82:29,83:30,84:31,85:32,69:35,80:43,157:44,135:46,139:47,141:48,77:57,78:58,39:59,45:61,35:73,62:74,144:80,41:83,5:221,14:$V0,30:$V1,36:$V2,40:$V3,42:$V4,43:$V5,46:$V6,47:$V7,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,63:$Ve,64:$Vf,65:$Vg,66:$Vh,70:$Vi,71:$Vj,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,136:$Vv,138:$Vw,140:$Vx,142:$Vy,152:$Vz,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG}),o($VZ,[2,263]),{7:222,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:223,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:224,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:225,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:226,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:227,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:228,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:229,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:230,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:231,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:232,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:233,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:234,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:235,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VZ,[2,213]),o($VZ,[2,218]),{7:236,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VZ,[2,212]),o($VZ,[2,217]),{41:237,42:$V4,43:$V5,115:238,117:$Vv1},o($Vr1,[2,92]),o($Vw1,[2,172]),{37:240,38:$Vq1},{37:241,38:$Vq1},o($Vr1,[2,110],{37:242,38:$Vq1}),{37:243,38:$Vq1},o($Vr1,[2,111]),{7:245,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,76:$Vx1,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,94:244,96:246,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,124:247,125:$Vy1,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{88:$V01,93:250,95:$V41},{115:251,117:$Vv1},o($Vr1,[2,93]),{6:[1,253],7:252,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,33:[1,254],35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{115:255,117:$Vv1},{37:256,38:$Vq1},{7:257,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o([6,33],$Vz1,{72:260,68:[1,258],73:$VA1}),o($VB1,[2,78]),o($VB1,[2,82],{57:[1,262],76:[1,261]}),o($VB1,[2,85]),o($VC1,[2,86]),o($VC1,[2,87]),o($VC1,[2,88]),o($VC1,[2,89]),{37:190,38:$Vq1},{7:263,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,33:$Vn1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,76:$Vo1,77:57,78:58,79:188,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,119:185,120:$Vp,121:$Vq,122:$Vr,123:$Vp1,126:186,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VZ,[2,72]),{4:265,5:3,7:4,8:5,9:6,10:25,11:26,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$V1,34:[1,264],35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VD1,[2,254],{144:80,135:105,141:106,166:$VM}),{7:145,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{135:108,136:$Vv,138:$Vw,141:109,142:$Vy,144:80,159:$VY},o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,166,167,168,169,170,171,172,173,174,175,176,177],$Vj1,{17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,12:20,13:21,15:23,16:24,56:27,49:28,82:29,83:30,84:31,85:32,69:35,80:43,157:44,135:46,139:47,141:48,77:57,78:58,39:59,45:61,35:73,62:74,144:80,41:83,8:140,7:166,14:$V0,30:$Ve1,31:$Vk1,36:$V2,40:$V3,42:$V4,43:$V5,46:$V6,47:$V7,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,70:$Vi,71:$Vj,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,140:$Vx,152:$Vz,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG}),o($VE1,[2,255],{144:80,135:105,141:106,166:$VM,168:$VO}),o($VE1,[2,256],{144:80,135:105,141:106,166:$VM,168:$VO}),o($VE1,[2,257],{144:80,135:105,141:106,166:$VM,168:$VO}),o($VD1,[2,258],{144:80,135:105,141:106,166:$VM}),o($VI,[2,69],{17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,12:20,13:21,15:23,16:24,56:27,49:28,82:29,83:30,84:31,85:32,69:35,80:43,157:44,135:46,139:47,141:48,77:57,78:58,39:59,45:61,35:73,62:74,144:80,41:83,8:140,7:266,14:$V0,30:$Ve1,36:$V2,40:$V3,42:$V4,43:$V5,46:$V6,47:$V7,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,70:$Vi,71:$Vj,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,136:$Vl1,138:$Vl1,142:$Vl1,159:$Vl1,140:$Vx,152:$Vz,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG}),o($VZ,[2,259],{42:$Vh1,43:$Vh1,87:$Vh1,88:$Vh1,90:$Vh1,91:$Vh1,92:$Vh1,95:$Vh1,116:$Vh1,117:$Vh1}),o($Vw1,$V_,{114:110,81:111,93:117,87:$V$,88:$V01,90:$V11,91:$V21,92:$V31,95:$V41,116:$V51}),{81:121,87:$V$,88:$V01,90:$V11,91:$V21,92:$V31,93:117,95:$V41,114:120,116:$V51,117:$V_},o($VF1,$V81),o($VZ,[2,260],{42:$Vh1,43:$Vh1,87:$Vh1,88:$Vh1,90:$Vh1,91:$Vh1,92:$Vh1,95:$Vh1,116:$Vh1,117:$Vh1}),o($VZ,[2,261]),o($VZ,[2,262]),{6:[1,269],7:267,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,33:[1,268],35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:270,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{32:271,33:$Vd1,158:[1,272]},o($VZ,[2,197],{129:273,130:[1,274],131:[1,275]}),o($VZ,[2,211]),o($VZ,[2,219]),{33:[1,276],135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},{153:277,155:278,156:$VG1},o($VZ,[2,123]),{7:280,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($Vi1,[2,126],{32:281,33:$Vd1,42:$Vh1,43:$Vh1,87:$Vh1,88:$Vh1,90:$Vh1,91:$Vh1,92:$Vh1,95:$Vh1,116:$Vh1,117:$Vh1,101:[1,282]}),o($VH1,[2,204],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VH1,[2,30],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{7:283,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VI,[2,67],{17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,12:20,13:21,15:23,16:24,56:27,49:28,82:29,83:30,84:31,85:32,69:35,80:43,157:44,135:46,139:47,141:48,77:57,78:58,39:59,45:61,35:73,62:74,144:80,41:83,8:140,7:284,14:$V0,30:$Ve1,36:$V2,40:$V3,42:$V4,43:$V5,46:$V6,47:$V7,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,70:$Vi,71:$Vj,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,136:$Vl1,138:$Vl1,142:$Vl1,159:$Vl1,140:$Vx,152:$Vz,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG}),o($V61,$VI1,{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($V61,[2,130]),{31:[1,285],73:[1,286]},{31:[1,287]},{33:$VJ1,35:292,36:$V2,99:[1,288],105:289,106:290,108:$VK1},o([31,73],[2,146]),{107:[1,294]},{33:$VL1,35:299,36:$V2,99:[1,295],108:$VM1,111:296,113:297},o($V61,[2,150]),{57:[1,301]},{7:302,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{31:[1,303]},{6:$VH,134:[1,304]},{4:305,5:3,7:4,8:5,9:6,10:25,11:26,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$V1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o([6,33,73,123],$VN1,{144:80,135:105,141:106,124:306,76:[1,307],125:$Vy1,136:$Vv,138:$Vw,142:$Vy,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VO1,[2,178]),o([6,33,123],$Vz1,{72:308,73:$VP1}),o($VQ1,[2,187]),{7:263,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,33:$Vn1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,76:$Vo1,77:57,78:58,79:188,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,119:310,120:$Vp,121:$Vq,122:$Vr,126:186,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VQ1,[2,193]),o($VQ1,[2,194]),o($VR1,[2,177]),o($VR1,[2,35]),{32:311,33:$Vd1,135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},o($VS1,[2,207],{144:80,135:105,141:106,136:$Vv,137:[1,312],138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VS1,[2,209],{144:80,135:105,141:106,136:$Vv,137:[1,313],138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VZ,[2,215]),o($VT1,[2,216],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,159,162,163,166,167,168,169,170,171,172,173,174,175,176,177],[2,220],{143:[1,314]}),o($VU1,[2,223]),{35:201,36:$V2,62:202,77:203,78:204,97:$Vl,121:$Vb1,122:$Vc1,146:315,148:200},o($VU1,[2,229],{73:[1,316]}),o($VV1,[2,225]),o($VV1,[2,226]),o($VV1,[2,227]),o($VV1,[2,228]),o($VZ,[2,222]),{7:317,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:318,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:319,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VW1,$Vz1,{72:320,73:$VX1}),o($VY1,[2,118]),o($VY1,[2,53],{60:[1,322]}),o($VZ1,[2,62],{57:[1,323]}),o($VY1,[2,58]),o($VZ1,[2,63]),o($V_1,[2,59]),o($V_1,[2,60]),o($V_1,[2,61]),{48:[1,324],81:121,87:$V$,88:$V01,90:$V11,91:$V21,92:$V31,93:117,95:$V41,114:120,116:$V51,117:$V_},o($VF1,$Vh1),{6:$VH,44:[1,325]},o($VI,[2,4]),o($V$1,[2,264],{144:80,135:105,141:106,166:$VM,167:$VN,168:$VO}),o($V$1,[2,265],{144:80,135:105,141:106,166:$VM,167:$VN,168:$VO}),o($VE1,[2,266],{144:80,135:105,141:106,166:$VM,168:$VO}),o($VE1,[2,267],{144:80,135:105,141:106,166:$VM,168:$VO}),o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,169,170,171,172,173,174,175,176,177],[2,268],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO}),o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,170,171,172,173,174,175,176],[2,269],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,177:$VX}),o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,171,172,173,174,175,176],[2,270],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,177:$VX}),o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,172,173,174,175,176],[2,271],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,177:$VX}),o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,173,174,175,176],[2,272],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,177:$VX}),o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,174,175,176],[2,273],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,177:$VX}),o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,175,176],[2,274],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,177:$VX}),o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,176],[2,275],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,177:$VX}),o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,143,159,170,171,172,173,174,175,176,177],[2,276],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP}),o($VT1,[2,253],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VT1,[2,252],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($V02,[2,167]),o($V02,[2,168]),{7:263,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,33:$Vn1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,76:$Vo1,77:57,78:58,79:188,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,118:[1,326],119:327,120:$Vp,121:$Vq,122:$Vr,126:186,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($Vr1,[2,106]),o($Vr1,[2,107]),o($Vr1,[2,108]),o($Vr1,[2,109]),{89:[1,328]},{76:$Vx1,89:[2,114],124:329,125:$Vy1,135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},{89:[2,115]},{7:330,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,89:[2,186],97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($V12,[2,180]),o($V12,$V22),o($Vr1,[2,113]),o($V02,[2,169]),o($VH1,[2,50],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{7:331,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:332,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($V02,[2,170]),o($V71,[2,104]),{89:[1,333],135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},{69:334,70:$Vi,71:$Vj},o($V32,$V42,{75:128,35:130,62:131,77:132,78:133,74:335,36:$V2,76:$Va1,97:$Vl,121:$Vb1,122:$Vc1}),{6:$V52,33:$V62},o($VB1,[2,83]),{7:338,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VQ1,$VN1,{144:80,135:105,141:106,76:[1,339],136:$Vv,138:$Vw,142:$Vy,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($V72,[2,32]),{6:$VH,34:[1,340]},o($VI,[2,68],{144:80,135:105,141:106,136:$VI1,138:$VI1,142:$VI1,159:$VI1,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VH1,[2,277],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{7:341,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:342,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VH1,[2,280],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VZ,[2,251]),{7:343,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VZ,[2,198],{130:[1,344]}),{32:345,33:$Vd1},{32:348,33:$Vd1,35:346,36:$V2,78:347,97:$Vl},{153:349,155:278,156:$VG1},{34:[1,350],154:[1,351],155:352,156:$VG1},o($V82,[2,244]),{7:354,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,127:353,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($V92,[2,124],{144:80,135:105,141:106,32:355,33:$Vd1,136:$Vv,138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VZ,[2,127]),{7:356,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VH1,[2,31],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VI,[2,66],{144:80,135:105,141:106,136:$VI1,138:$VI1,142:$VI1,159:$VI1,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{41:357,42:$V4,43:$V5},{97:[1,359],104:358,109:$Vm1},{41:360,42:$V4,43:$V5},{31:[1,361]},o($VW1,$Vz1,{72:362,73:$Va2}),o($VY1,[2,137]),{33:$VJ1,35:292,36:$V2,105:364,106:290,108:$VK1},o($VY1,[2,142],{107:[1,365]}),o($VY1,[2,144],{107:[1,366]}),{35:367,36:$V2},o($V61,[2,148]),o($VW1,$Vz1,{72:368,73:$Vb2}),o($VY1,[2,157]),{33:$VL1,35:299,36:$V2,108:$VM1,111:370,113:297},o($VY1,[2,162],{107:[1,371]}),o($VY1,[2,165],{107:[1,372]}),{6:[1,374],7:373,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,33:[1,375],35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($Vc2,[2,154],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{41:376,42:$V4,43:$V5},o($V71,[2,205]),{6:$VH,34:[1,377]},{7:378,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o([14,30,36,40,42,43,46,47,50,51,52,53,54,55,63,64,65,66,70,71,86,97,100,102,110,120,121,122,128,132,133,136,138,140,142,152,158,160,161,162,163,164,165],$V22,{6:$Vd2,33:$Vd2,73:$Vd2,123:$Vd2}),{6:$Ve2,33:$Vf2,123:[1,379]},o([6,33,34,118,123],$V42,{17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,12:20,13:21,15:23,16:24,56:27,49:28,82:29,83:30,84:31,85:32,69:35,80:43,157:44,135:46,139:47,141:48,77:57,78:58,39:59,45:61,35:73,62:74,144:80,41:83,8:140,79:188,7:263,126:382,14:$V0,30:$Ve1,36:$V2,40:$V3,42:$V4,43:$V5,46:$V6,47:$V7,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,70:$Vi,71:$Vj,76:$Vo1,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,136:$Vv,138:$Vw,140:$Vx,142:$Vy,152:$Vz,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG}),o($V32,$Vz1,{72:383,73:$VP1}),o($Vg2,[2,248]),{7:384,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:385,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:386,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VU1,[2,224]),{35:201,36:$V2,62:202,77:203,78:204,97:$Vl,121:$Vb1,122:$Vc1,148:387},o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,138,142,159],[2,231],{144:80,135:105,141:106,137:[1,388],143:[1,389],162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($Vh2,[2,232],{144:80,135:105,141:106,137:[1,390],162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($Vh2,[2,238],{144:80,135:105,141:106,137:[1,391],162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{6:$Vi2,33:$Vj2,99:[1,392]},o($Vk2,$V42,{41:83,59:211,61:212,13:213,39:214,35:215,37:216,62:217,58:395,36:$V2,38:$Vq1,40:$V3,42:$V4,43:$V5,65:$Vg,121:$Vb1}),{7:396,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,33:[1,397],35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:398,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,33:[1,399],35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($V71,[2,41]),o($Vu1,[2,39]),o($V02,[2,173]),o([6,33,118],$Vz1,{72:400,73:$VP1}),o($Vr1,[2,112]),{7:401,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,89:[2,184],97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{89:[2,185],135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},o($VH1,[2,51],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{34:[1,402],135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},o($V71,[2,105]),{32:403,33:$Vd1},o($VB1,[2,79]),{35:130,36:$V2,62:131,74:404,75:128,76:$Va1,77:132,78:133,97:$Vl,121:$Vb1,122:$Vc1},o($Vl2,$V91,{74:127,75:128,35:130,62:131,77:132,78:133,67:405,36:$V2,76:$Va1,97:$Vl,121:$Vb1,122:$Vc1}),o($VB1,[2,84],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VQ1,$Vd2),o($V72,[2,33]),{34:[1,406],135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},o($VH1,[2,279],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{32:407,33:$Vd1,135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},{32:408,33:$Vd1},o($VZ,[2,199]),{32:409,33:$Vd1},{32:410,33:$Vd1},o($Vm2,[2,203]),{34:[1,411],154:[1,412],155:352,156:$VG1},o($VZ,[2,242]),{32:413,33:$Vd1},o($V82,[2,245]),{32:414,33:$Vd1,73:[1,415]},o($Vn2,[2,195],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VZ,[2,125]),o($V92,[2,128],{144:80,135:105,141:106,32:416,33:$Vd1,136:$Vv,138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($V61,[2,131]),{31:[1,417]},{33:$VJ1,35:292,36:$V2,105:418,106:290,108:$VK1},o($V61,[2,132]),{41:419,42:$V4,43:$V5},{6:$Vo2,33:$Vp2,99:[1,420]},o($Vk2,$V42,{35:292,106:423,36:$V2,108:$VK1}),o($V32,$Vz1,{72:424,73:$Va2}),{35:425,36:$V2},{35:426,36:$V2},{31:[2,147]},{6:$Vq2,33:$Vr2,99:[1,427]},o($Vk2,$V42,{35:299,113:430,36:$V2,108:$VM1}),o($V32,$Vz1,{72:431,73:$Vb2}),{35:432,36:$V2,108:[1,433]},{35:434,36:$V2},o($Vc2,[2,151],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{7:435,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:436,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($V61,[2,155]),{134:[1,437]},{123:[1,438],135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},o($VO1,[2,179]),{7:263,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,76:$Vo1,77:57,78:58,79:188,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,126:439,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:263,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,33:$Vn1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,76:$Vo1,77:57,78:58,79:188,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,119:440,120:$Vp,121:$Vq,122:$Vr,126:186,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VQ1,[2,188]),{6:$Ve2,33:$Vf2,34:[1,441]},o($VT1,[2,208],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VT1,[2,210],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VT1,[2,221],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VU1,[2,230]),{7:442,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:443,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:444,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:445,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VO1,[2,116]),{13:213,35:215,36:$V2,37:216,38:$Vq1,39:214,40:$V3,41:83,42:$V4,43:$V5,58:446,59:211,61:212,62:217,65:$Vg,121:$Vb1},o($Vl2,$Vs1,{41:83,58:210,59:211,61:212,13:213,39:214,35:215,37:216,62:217,98:447,36:$V2,38:$Vq1,40:$V3,42:$V4,43:$V5,65:$Vg,121:$Vb1}),o($VY1,[2,119]),o($VY1,[2,54],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{7:448,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VY1,[2,56],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{7:449,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{6:$Ve2,33:$Vf2,118:[1,450]},{89:[2,183],135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},o($VZ,[2,52]),o($VZ,[2,71]),o($VB1,[2,80]),o($V32,$Vz1,{72:451,73:$VA1}),o($VZ,[2,278]),o($Vg2,[2,249]),o($VZ,[2,200]),o($Vm2,[2,201]),o($Vm2,[2,202]),o($VZ,[2,240]),{32:452,33:$Vd1},{34:[1,453]},o($V82,[2,246],{6:[1,454]}),{7:455,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},o($VZ,[2,129]),{41:456,42:$V4,43:$V5},o($VW1,$Vz1,{72:457,73:$Va2}),o($V61,[2,133]),{31:[1,458]},{35:292,36:$V2,106:459,108:$VK1},{33:$VJ1,35:292,36:$V2,105:460,106:290,108:$VK1},o($VY1,[2,138]),{6:$Vo2,33:$Vp2,34:[1,461]},o($VY1,[2,143]),o($VY1,[2,145]),o($V61,[2,149],{31:[1,462]}),{35:299,36:$V2,108:$VM1,113:463},{33:$VL1,35:299,36:$V2,108:$VM1,111:464,113:297},o($VY1,[2,158]),{6:$Vq2,33:$Vr2,34:[1,465]},o($VY1,[2,163]),o($VY1,[2,164]),o($VY1,[2,166]),o($Vc2,[2,152],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),{34:[1,466],135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},o($V71,[2,206]),o($V71,[2,182]),o($VQ1,[2,189]),o($V32,$Vz1,{72:467,73:$VP1}),o($VQ1,[2,190]),o([1,6,33,34,44,68,73,76,89,99,118,123,125,134,136,137,138,142,159],[2,233],{144:80,135:105,141:106,143:[1,468],162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($Vh2,[2,235],{144:80,135:105,141:106,137:[1,469],162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VH1,[2,234],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VH1,[2,239],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VY1,[2,120]),o($V32,$Vz1,{72:470,73:$VX1}),{34:[1,471],135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},{34:[1,472],135:105,136:$Vv,138:$Vw,141:106,142:$Vy,144:80,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX},o($V02,[2,174]),{6:$V52,33:$V62,34:[1,473]},{34:[1,474]},o($VZ,[2,243]),o($V82,[2,247]),o($Vn2,[2,196],{144:80,135:105,141:106,136:$Vv,138:$Vw,142:$Vy,159:$VJ,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($V61,[2,135]),{6:$Vo2,33:$Vp2,99:[1,475]},{41:476,42:$V4,43:$V5},o($VY1,[2,139]),o($V32,$Vz1,{72:477,73:$Va2}),o($VY1,[2,140]),{41:478,42:$V4,43:$V5},o($VY1,[2,159]),o($V32,$Vz1,{72:479,73:$Vb2}),o($VY1,[2,160]),o($V61,[2,153]),{6:$Ve2,33:$Vf2,34:[1,480]},{7:481,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{7:482,8:140,12:20,13:21,14:$V0,15:23,16:24,17:7,18:8,19:9,20:10,21:11,22:12,23:13,24:14,25:15,26:16,27:17,28:18,29:19,30:$Ve1,35:73,36:$V2,39:59,40:$V3,41:83,42:$V4,43:$V5,45:61,46:$V6,47:$V7,49:28,50:$V8,51:$V9,52:$Va,53:$Vb,54:$Vc,55:$Vd,56:27,62:74,63:$Ve,64:$Vf1,65:$Vg,66:$Vh,69:35,70:$Vi,71:$Vj,77:57,78:58,80:43,82:29,83:30,84:31,85:32,86:$Vk,97:$Vl,100:$Vm,102:$Vn,110:$Vo,120:$Vp,121:$Vq,122:$Vr,128:$Vs,132:$Vt,133:$Vu,135:46,136:$Vv,138:$Vw,139:47,140:$Vx,141:48,142:$Vy,144:80,152:$Vz,157:44,158:$VA,160:$VB,161:$VC,162:$VD,163:$VE,164:$VF,165:$VG},{6:$Vi2,33:$Vj2,34:[1,483]},o($VY1,[2,55]),o($VY1,[2,57]),o($VB1,[2,81]),o($VZ,[2,241]),{31:[1,484]},o($V61,[2,134]),{6:$Vo2,33:$Vp2,34:[1,485]},o($V61,[2,156]),{6:$Vq2,33:$Vr2,34:[1,486]},o($VQ1,[2,191]),o($VH1,[2,236],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VH1,[2,237],{144:80,135:105,141:106,162:$VK,163:$VL,166:$VM,167:$VN,168:$VO,169:$VP,170:$VQ,171:$VR,172:$VS,173:$VT,174:$VU,175:$VV,176:$VW,177:$VX}),o($VY1,[2,121]),{41:487,42:$V4,43:$V5},o($VY1,[2,141]),o($VY1,[2,161]),o($V61,[2,136])],
defaultActions: {71:[2,73],72:[2,74],246:[2,115],367:[2,147]},
parseError: function parseError(str, hash) {
    if (hash.recoverable) {
        this.trace(str);
    } else {
        function _parseError (msg, hash) {
            this.message = msg;
            this.hash = hash;
        }
        _parseError.prototype = Error;

        throw new _parseError(str, hash);
    }
},
parse: function parse(input) {
    var self = this, stack = [0], tstack = [], vstack = [null], lstack = [], table = this.table, yytext = '', yylineno = 0, yyleng = 0, recovering = 0, TERROR = 2, EOF = 1;
    var args = lstack.slice.call(arguments, 1);
    var lexer = Object.create(this.lexer);
    var sharedState = { yy: {} };
    for (var k in this.yy) {
        if (Object.prototype.hasOwnProperty.call(this.yy, k)) {
            sharedState.yy[k] = this.yy[k];
        }
    }
    lexer.setInput(input, sharedState.yy);
    sharedState.yy.lexer = lexer;
    sharedState.yy.parser = this;
    if (typeof lexer.yylloc == 'undefined') {
        lexer.yylloc = {};
    }
    var yyloc = lexer.yylloc;
    lstack.push(yyloc);
    var ranges = lexer.options && lexer.options.ranges;
    if (typeof sharedState.yy.parseError === 'function') {
        this.parseError = sharedState.yy.parseError;
    } else {
        this.parseError = Object.getPrototypeOf(this).parseError;
    }
    function popStack(n) {
        stack.length = stack.length - 2 * n;
        vstack.length = vstack.length - n;
        lstack.length = lstack.length - n;
    }
    _token_stack:
        var lex = function () {
            var token;
            token = lexer.lex() || EOF;
            if (typeof token !== 'number') {
                token = self.symbols_[token] || token;
            }
            return token;
        };
    var symbol, preErrorSymbol, state, action, a, r, yyval = {}, p, len, newState, expected;
    while (true) {
        state = stack[stack.length - 1];
        if (this.defaultActions[state]) {
            action = this.defaultActions[state];
        } else {
            if (symbol === null || typeof symbol == 'undefined') {
                symbol = lex();
            }
            action = table[state] && table[state][symbol];
        }
                    if (typeof action === 'undefined' || !action.length || !action[0]) {
                var errStr = '';
                expected = [];
                for (p in table[state]) {
                    if (this.terminals_[p] && p > TERROR) {
                        expected.push('\'' + this.terminals_[p] + '\'');
                    }
                }
                if (lexer.showPosition) {
                    errStr = 'Parse error on line ' + (yylineno + 1) + ':\n' + lexer.showPosition() + '\nExpecting ' + expected.join(', ') + ', got \'' + (this.terminals_[symbol] || symbol) + '\'';
                } else {
                    errStr = 'Parse error on line ' + (yylineno + 1) + ': Unexpected ' + (symbol == EOF ? 'end of input' : '\'' + (this.terminals_[symbol] || symbol) + '\'');
                }
                this.parseError(errStr, {
                    text: lexer.match,
                    token: this.terminals_[symbol] || symbol,
                    line: lexer.yylineno,
                    loc: yyloc,
                    expected: expected
                });
            }
        if (action[0] instanceof Array && action.length > 1) {
            throw new Error('Parse Error: multiple actions possible at state: ' + state + ', token: ' + symbol);
        }
        switch (action[0]) {
        case 1:
            stack.push(symbol);
            vstack.push(lexer.yytext);
            lstack.push(lexer.yylloc);
            stack.push(action[1]);
            symbol = null;
            if (!preErrorSymbol) {
                yyleng = lexer.yyleng;
                yytext = lexer.yytext;
                yylineno = lexer.yylineno;
                yyloc = lexer.yylloc;
                if (recovering > 0) {
                    recovering--;
                }
            } else {
                symbol = preErrorSymbol;
                preErrorSymbol = null;
            }
            break;
        case 2:
            len = this.productions_[action[1]][1];
            yyval.$ = vstack[vstack.length - len];
            yyval._$ = {
                first_line: lstack[lstack.length - (len || 1)].first_line,
                last_line: lstack[lstack.length - 1].last_line,
                first_column: lstack[lstack.length - (len || 1)].first_column,
                last_column: lstack[lstack.length - 1].last_column
            };
            if (ranges) {
                yyval._$.range = [
                    lstack[lstack.length - (len || 1)].range[0],
                    lstack[lstack.length - 1].range[1]
                ];
            }
            r = this.performAction.apply(yyval, [
                yytext,
                yyleng,
                yylineno,
                sharedState.yy,
                action[1],
                vstack,
                lstack
            ].concat(args));
            if (typeof r !== 'undefined') {
                return r;
            }
            if (len) {
                stack = stack.slice(0, -1 * len * 2);
                vstack = vstack.slice(0, -1 * len);
                lstack = lstack.slice(0, -1 * len);
            }
            stack.push(this.productions_[action[1]][0]);
            vstack.push(yyval.$);
            lstack.push(yyval._$);
            newState = table[stack[stack.length - 2]][stack[stack.length - 1]];
            stack.push(newState);
            break;
        case 3:
            return true;
        }
    }
    return true;
}};

function Parser () {
  this.yy = {};
}
Parser.prototype = parser;parser.Parser = Parser;
return new Parser;
})();


if (typeof require !== 'undefined' && typeof exports !== 'undefined') {
exports.parser = parser;
exports.Parser = parser.Parser;
exports.parse = function () { return parser.parse.apply(parser, arguments); };
exports.main = function commonjsMain(args) {
    if (!args[1]) {
        console.log('Usage: '+args[0]+' FILE');
        process.exit(1);
    }
    var source = '';
    var fs = require('fs');
    if (typeof fs !== 'undefined' && fs !== null)
        source = fs.readFileSync(require('path').normalize(args[1]), "utf8");
    return exports.parser.parse(source);
};
if (typeof module !== 'undefined' && require.main === module) {
  exports.main(process.argv.slice(1));
}
}
  return module.exports;
})();require['./scope'] = (function() {
  var exports = {}, module = {exports: exports};
  // Generated by CoffeeScript 2.0.0-alpha1
(function() {
  var Scope,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  exports.Scope = Scope = class Scope {
    constructor(parent, expressions, method, referencedVars) {
      var ref, ref1;
      this.parent = parent;
      this.expressions = expressions;
      this.method = method;
      this.referencedVars = referencedVars;
      this.variables = [
        {
          name: 'arguments',
          type: 'arguments'
        }
      ];
      this.positions = {};
      if (!this.parent) {
        this.utilities = {};
      }
      this.root = (ref = (ref1 = this.parent) != null ? ref1.root : void 0) != null ? ref : this;
    }

    add(name, type, immediate) {
      if (this.shared && !immediate) {
        return this.parent.add(name, type, immediate);
      }
      if (Object.prototype.hasOwnProperty.call(this.positions, name)) {
        return this.variables[this.positions[name]].type = type;
      } else {
        return this.positions[name] = this.variables.push({name, type}) - 1;
      }
    }

    namedMethod() {
      var ref;
      if (((ref = this.method) != null ? ref.name : void 0) || !this.parent) {
        return this.method;
      }
      return this.parent.namedMethod();
    }

    find(name, type = 'var') {
      if (this.check(name)) {
        return true;
      }
      this.add(name, type);
      return false;
    }

    parameter(name) {
      if (this.shared && this.parent.check(name, true)) {
        return;
      }
      return this.add(name, 'param');
    }

    check(name) {
      var ref;
      return !!(this.type(name) || ((ref = this.parent) != null ? ref.check(name) : void 0));
    }

    temporary(name, index, single = false) {
      var diff, endCode, letter, newCode, num, startCode;
      if (single) {
        startCode = name.charCodeAt(0);
        endCode = 'z'.charCodeAt(0);
        diff = endCode - startCode;
        newCode = startCode + index % (diff + 1);
        letter = String.fromCharCode(newCode);
        num = Math.floor(index / (diff + 1));
        return `${letter}${num || ''}`;
      } else {
        return `${name}${index || ''}`;
      }
    }

    type(name) {
      var i, len, ref, v;
      ref = this.variables;
      for (i = 0, len = ref.length; i < len; i++) {
        v = ref[i];
        if (v.name === name) {
          return v.type;
        }
      }
      return null;
    }

    freeVariable(name, options = {}) {
      var index, ref, temp;
      index = 0;
      while (true) {
        temp = this.temporary(name, index, options.single);
        if (!(this.check(temp) || indexOf.call(this.root.referencedVars, temp) >= 0)) {
          break;
        }
        index++;
      }
      if ((ref = options.reserve) != null ? ref : true) {
        this.add(temp, 'var', true);
      }
      return temp;
    }

    assign(name, value) {
      this.add(name, {
        value,
        assigned: true
      }, true);
      return this.hasAssignments = true;
    }

    hasDeclarations() {
      return !!this.declaredVariables().length;
    }

    declaredVariables() {
      var v;
      return ((function() {
        var i, len, ref, results;
        ref = this.variables;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          v = ref[i];
          if (v.type === 'var') {
            results.push(v.name);
          }
        }
        return results;
      }).call(this)).sort();
    }

    assignedVariables() {
      var i, len, ref, results, v;
      ref = this.variables;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        v = ref[i];
        if (v.type.assigned) {
          results.push(`${v.name} = ${v.type.value}`);
        }
      }
      return results;
    }

  };

}).call(this);

  return module.exports;
})();require['./nodes'] = (function() {
  var exports = {}, module = {exports: exports};
  // Generated by CoffeeScript 2.0.0-alpha1
(function() {
  var Access, Arr, Assign, AwaitReturn, Base, Block, BooleanLiteral, Call, Class, Code, CodeFragment, Comment, ExecutableClassBody, Existence, Expansion, ExportAllDeclaration, ExportDeclaration, ExportDefaultDeclaration, ExportNamedDeclaration, ExportSpecifier, ExportSpecifierList, Extends, For, HoistTarget, IdentifierLiteral, If, ImportClause, ImportDeclaration, ImportDefaultSpecifier, ImportNamespaceSpecifier, ImportSpecifier, ImportSpecifierList, In, Index, InfinityLiteral, JS_FORBIDDEN, LEVEL_ACCESS, LEVEL_COND, LEVEL_LIST, LEVEL_OP, LEVEL_PAREN, LEVEL_TOP, Literal, ModuleDeclaration, ModuleSpecifier, ModuleSpecifierList, NEGATE, NO, NaNLiteral, NullLiteral, NumberLiteral, Obj, Op, Param, Parens, PassthroughLiteral, PropertyName, Range, RegexLiteral, RegexWithInterpolations, Return, SIMPLENUM, Scope, Slice, Splat, StatementLiteral, StringLiteral, StringWithInterpolations, Super, SuperCall, Switch, TAB, THIS, TaggedTemplateCall, ThisLiteral, Throw, Try, UTILITIES, UndefinedLiteral, Value, While, YES, YieldReturn, addLocationDataFn, compact, del, ends, extend, flatten, fragmentsToText, isLiteralArguments, isLiteralThis, isUnassignable, locationDataToString, merge, multident, shouldCacheOrIsAssignable, some, starts, throwSyntaxError, unfoldSoak, utility,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    slice = [].slice;

  Error.stackTraceLimit = 2e308;

  ({Scope} = require('./scope'));

  ({isUnassignable, JS_FORBIDDEN} = require('./lexer'));

  ({compact, flatten, extend, merge, del, starts, ends, some, addLocationDataFn, locationDataToString, throwSyntaxError} = require('./helpers'));

  exports.extend = extend;

  exports.addLocationDataFn = addLocationDataFn;

  YES = function() {
    return true;
  };

  NO = function() {
    return false;
  };

  THIS = function() {
    return this;
  };

  NEGATE = function() {
    this.negated = !this.negated;
    return this;
  };

  exports.CodeFragment = CodeFragment = class CodeFragment {
    constructor(parent, code) {
      var ref1;
      this.code = `${code}`;
      this.locationData = parent != null ? parent.locationData : void 0;
      this.type = (parent != null ? (ref1 = parent.constructor) != null ? ref1.name : void 0 : void 0) || 'unknown';
    }

    toString() {
      return `${this.code}${(this.locationData ? ": " + locationDataToString(this.locationData) : '')}`;
    }

  };

  fragmentsToText = function(fragments) {
    var fragment;
    return ((function() {
      var j, len1, results;
      results = [];
      for (j = 0, len1 = fragments.length; j < len1; j++) {
        fragment = fragments[j];
        results.push(fragment.code);
      }
      return results;
    })()).join('');
  };

  exports.Base = Base = (function() {
    class Base {
      compile(o, lvl) {
        return fragmentsToText(this.compileToFragments(o, lvl));
      }

      compileToFragments(o, lvl) {
        var node;
        o = extend({}, o);
        if (lvl) {
          o.level = lvl;
        }
        node = this.unfoldSoak(o) || this;
        node.tab = o.indent;
        if (o.level === LEVEL_TOP || !node.isStatement(o)) {
          return node.compileNode(o);
        } else {
          return node.compileClosure(o);
        }
      }

      compileClosure(o) {
        var args, argumentsNode, func, jumpNode, meth, parts, ref1, ref2;
        if (jumpNode = this.jumps()) {
          jumpNode.error('cannot use a pure statement in an expression');
        }
        o.sharedScope = true;
        func = new Code([], Block.wrap([this]));
        args = [];
        if (this.contains((function(node) {
          return node instanceof SuperCall;
        }))) {
          func.bound = true;
        } else if ((argumentsNode = this.contains(isLiteralArguments)) || this.contains(isLiteralThis)) {
          args = [new ThisLiteral];
          if (argumentsNode) {
            meth = 'apply';
            args.push(new IdentifierLiteral('arguments'));
          } else {
            meth = 'call';
          }
          func = new Value(func, [new Access(new PropertyName(meth))]);
        }
        parts = (new Call(func, args)).compileNode(o);
        switch (false) {
          case !(func.isGenerator || ((ref1 = func.base) != null ? ref1.isGenerator : void 0)):
            parts.unshift(this.makeCode("(yield* "));
            parts.push(this.makeCode(")"));
            break;
          case !(func.isAsync || ((ref2 = func.base) != null ? ref2.isAsync : void 0)):
            parts.unshift(this.makeCode("(await "));
            parts.push(this.makeCode(")"));
        }
        return parts;
      }

      cache(o, level, shouldCache) {
        var complex, ref, sub;
        complex = shouldCache != null ? shouldCache(this) : this.shouldCache();
        if (complex) {
          ref = new IdentifierLiteral(o.scope.freeVariable('ref'));
          sub = new Assign(ref, this);
          if (level) {
            return [sub.compileToFragments(o, level), [this.makeCode(ref.value)]];
          } else {
            return [sub, ref];
          }
        } else {
          ref = level ? this.compileToFragments(o, level) : this;
          return [ref, ref];
        }
      }

      hoist() {
        var compileNode, compileToFragments, target;
        this.hoisted = true;
        target = new HoistTarget(this);
        compileNode = this.compileNode;
        compileToFragments = this.compileToFragments;
        this.compileNode = function(o) {
          return target.update(compileNode, o);
        };
        this.compileToFragments = function(o) {
          return target.update(compileToFragments, o);
        };
        return target;
      }

      cacheToCodeFragments(cacheValues) {
        return [fragmentsToText(cacheValues[0]), fragmentsToText(cacheValues[1])];
      }

      makeReturn(res) {
        var me;
        me = this.unwrapAll();
        if (res) {
          return new Call(new Literal(`${res}.push`), [me]);
        } else {
          return new Return(me);
        }
      }

      contains(pred) {
        var node;
        node = void 0;
        this.traverseChildren(false, function(n) {
          if (pred(n)) {
            node = n;
            return false;
          }
        });
        return node;
      }

      lastNonComment(list) {
        var i;
        i = list.length;
        while (i--) {
          if (!(list[i] instanceof Comment)) {
            return list[i];
          }
        }
        return null;
      }

      toString(idt = '', name = this.constructor.name) {
        var tree;
        tree = '\n' + idt + name;
        if (this.soak) {
          tree += '?';
        }
        this.eachChild(function(node) {
          return tree += node.toString(idt + TAB);
        });
        return tree;
      }

      eachChild(func) {
        var attr, child, j, k, len1, len2, ref1, ref2;
        if (!this.children) {
          return this;
        }
        ref1 = this.children;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          attr = ref1[j];
          if (this[attr]) {
            ref2 = flatten([this[attr]]);
            for (k = 0, len2 = ref2.length; k < len2; k++) {
              child = ref2[k];
              if (func(child) === false) {
                return this;
              }
            }
          }
        }
        return this;
      }

      traverseChildren(crossScope, func) {
        return this.eachChild(function(child) {
          var recur;
          recur = func(child);
          if (recur !== false) {
            return child.traverseChildren(crossScope, func);
          }
        });
      }

      replaceInContext(match, replacement) {
        var attr, child, children, i, j, k, len1, len2, ref1, ref2;
        if (!this.children) {
          return false;
        }
        ref1 = this.children;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          attr = ref1[j];
          if (children = this[attr]) {
            if (Array.isArray(children)) {
              for (i = k = 0, len2 = children.length; k < len2; i = ++k) {
                child = children[i];
                if (match(child)) {
                  [].splice.apply(children, [i, i - i + 1].concat(ref2 = replacement(child, this))), ref2;
                  return true;
                } else {
                  if (child.replaceInContext(match, replacement)) {
                    return true;
                  }
                }
              }
            } else if (match(children)) {
              this[attr] = replacement(children, this);
              return true;
            } else {
              if (children.replaceInContext(match, replacement)) {
                return true;
              }
            }
          }
        }
      }

      invert() {
        return new Op('!', this);
      }

      unwrapAll() {
        var node;
        node = this;
        while (node !== (node = node.unwrap())) {
          continue;
        }
        return node;
      }

      updateLocationDataIfMissing(locationData) {
        if (this.locationData) {
          return this;
        }
        this.locationData = locationData;
        return this.eachChild(function(child) {
          return child.updateLocationDataIfMissing(locationData);
        });
      }

      error(message) {
        return throwSyntaxError(message, this.locationData);
      }

      makeCode(code) {
        return new CodeFragment(this, code);
      }

      wrapInParentheses(fragments) {
        return [].concat(this.makeCode('('), fragments, this.makeCode(')'));
      }

      joinFragmentArrays(fragmentsList, joinStr) {
        var answer, fragments, i, j, len1;
        answer = [];
        for (i = j = 0, len1 = fragmentsList.length; j < len1; i = ++j) {
          fragments = fragmentsList[i];
          if (i) {
            answer.push(this.makeCode(joinStr));
          }
          answer = answer.concat(fragments);
        }
        return answer;
      }

    };

    Base.prototype.children = [];

    Base.prototype.isStatement = NO;

    Base.prototype.jumps = NO;

    Base.prototype.shouldCache = YES;

    Base.prototype.isChainable = NO;

    Base.prototype.isAssignable = NO;

    Base.prototype.isNumber = NO;

    Base.prototype.unwrap = THIS;

    Base.prototype.unfoldSoak = NO;

    Base.prototype.assigns = NO;

    return Base;

  })();

  exports.HoistTarget = HoistTarget = class HoistTarget extends Base {
    static expand(fragments) {
      var fragment, i, j, ref1;
      for (i = j = fragments.length - 1; j >= 0; i = j += -1) {
        fragment = fragments[i];
        if (fragment.fragments) {
          [].splice.apply(fragments, [i, i - i + 1].concat(ref1 = this.expand(fragment.fragments))), ref1;
        }
      }
      return fragments;
    }

    constructor(source1) {
      super();
      this.source = source1;
      this.options = {};
      this.targetFragments = {
        fragments: []
      };
    }

    isStatement(o) {
      return this.source.isStatement(o);
    }

    update(compile, o) {
      return this.targetFragments.fragments = compile.call(this.source, merge(o, this.options));
    }

    compileToFragments(o, level) {
      this.options.indent = o.indent;
      this.options.level = level != null ? level : o.level;
      return [this.targetFragments];
    }

    compileNode(o) {
      return this.compileToFragments(o);
    }

    compileClosure(o) {
      return this.compileToFragments(o);
    }

  };

  exports.Block = Block = (function() {
    class Block extends Base {
      constructor(nodes) {
        super();
        this.expressions = compact(flatten(nodes || []));
      }

      push(node) {
        this.expressions.push(node);
        return this;
      }

      pop() {
        return this.expressions.pop();
      }

      unshift(node) {
        this.expressions.unshift(node);
        return this;
      }

      unwrap() {
        if (this.expressions.length === 1) {
          return this.expressions[0];
        } else {
          return this;
        }
      }

      isEmpty() {
        return !this.expressions.length;
      }

      isStatement(o) {
        var exp, j, len1, ref1;
        ref1 = this.expressions;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          exp = ref1[j];
          if (exp.isStatement(o)) {
            return true;
          }
        }
        return false;
      }

      jumps(o) {
        var exp, j, jumpNode, len1, ref1;
        ref1 = this.expressions;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          exp = ref1[j];
          if (jumpNode = exp.jumps(o)) {
            return jumpNode;
          }
        }
      }

      makeReturn(res) {
        var expr, len;
        len = this.expressions.length;
        while (len--) {
          expr = this.expressions[len];
          if (!(expr instanceof Comment)) {
            this.expressions[len] = expr.makeReturn(res);
            if (expr instanceof Return && !expr.expression) {
              this.expressions.splice(len, 1);
            }
            break;
          }
        }
        return this;
      }

      compileToFragments(o = {}, level) {
        if (o.scope) {
          return super.compileToFragments(o, level);
        } else {
          return this.compileRoot(o);
        }
      }

      compileNode(o) {
        var answer, compiledNodes, fragments, index, j, len1, node, ref1, top;
        this.tab = o.indent;
        top = o.level === LEVEL_TOP;
        compiledNodes = [];
        ref1 = this.expressions;
        for (index = j = 0, len1 = ref1.length; j < len1; index = ++j) {
          node = ref1[index];
          node = node.unwrapAll();
          node = node.unfoldSoak(o) || node;
          if (node instanceof Block) {
            compiledNodes.push(node.compileNode(o));
          } else if (node.hoisted) {
            node.compileToFragments(o);
          } else if (top) {
            node.front = true;
            fragments = node.compileToFragments(o);
            if (!node.isStatement(o)) {
              fragments.unshift(this.makeCode(`${this.tab}`));
              fragments.push(this.makeCode(";"));
            }
            compiledNodes.push(fragments);
          } else {
            compiledNodes.push(node.compileToFragments(o, LEVEL_LIST));
          }
        }
        if (top) {
          if (this.spaced) {
            return [].concat(this.joinFragmentArrays(compiledNodes, '\n\n'), this.makeCode("\n"));
          } else {
            return this.joinFragmentArrays(compiledNodes, '\n');
          }
        }
        if (compiledNodes.length) {
          answer = this.joinFragmentArrays(compiledNodes, ', ');
        } else {
          answer = [this.makeCode("void 0")];
        }
        if (compiledNodes.length > 1 && o.level >= LEVEL_LIST) {
          return this.wrapInParentheses(answer);
        } else {
          return answer;
        }
      }

      compileRoot(o) {
        var exp, fragments, i, j, len1, name, prelude, preludeExps, ref1, ref2, rest;
        o.indent = o.bare ? '' : TAB;
        o.level = LEVEL_TOP;
        this.spaced = true;
        o.scope = new Scope(null, this, null, (ref1 = o.referencedVars) != null ? ref1 : []);
        ref2 = o.locals || [];
        for (j = 0, len1 = ref2.length; j < len1; j++) {
          name = ref2[j];
          o.scope.parameter(name);
        }
        prelude = [];
        if (!o.bare) {
          preludeExps = (function() {
            var k, len2, ref3, results;
            ref3 = this.expressions;
            results = [];
            for (i = k = 0, len2 = ref3.length; k < len2; i = ++k) {
              exp = ref3[i];
              if (!(exp.unwrap() instanceof Comment)) {
                break;
              }
              results.push(exp);
            }
            return results;
          }).call(this);
          rest = this.expressions.slice(preludeExps.length);
          this.expressions = preludeExps;
          if (preludeExps.length) {
            prelude = this.compileNode(merge(o, {
              indent: ''
            }));
            prelude.push(this.makeCode("\n"));
          }
          this.expressions = rest;
        }
        fragments = this.compileWithDeclarations(o);
        HoistTarget.expand(fragments);
        if (o.bare) {
          return fragments;
        }
        return [].concat(prelude, this.makeCode("(function() {\n"), fragments, this.makeCode("\n}).call(this);\n"));
      }

      compileWithDeclarations(o) {
        var assigns, declars, exp, fragments, i, j, len1, post, ref1, rest, scope, spaced;
        fragments = [];
        post = [];
        ref1 = this.expressions;
        for (i = j = 0, len1 = ref1.length; j < len1; i = ++j) {
          exp = ref1[i];
          exp = exp.unwrap();
          if (!(exp instanceof Comment || exp instanceof Literal)) {
            break;
          }
        }
        o = merge(o, {
          level: LEVEL_TOP
        });
        if (i) {
          rest = this.expressions.splice(i, 9e9);
          [spaced, this.spaced] = [this.spaced, false];
          [fragments, this.spaced] = [this.compileNode(o), spaced];
          this.expressions = rest;
        }
        post = this.compileNode(o);
        ({scope} = o);
        if (scope.expressions === this) {
          declars = o.scope.hasDeclarations();
          assigns = scope.hasAssignments;
          if (declars || assigns) {
            if (i) {
              fragments.push(this.makeCode('\n'));
            }
            fragments.push(this.makeCode(`${this.tab}var `));
            if (declars) {
              fragments.push(this.makeCode(scope.declaredVariables().join(', ')));
            }
            if (assigns) {
              if (declars) {
                fragments.push(this.makeCode(`,\n${this.tab + TAB}`));
              }
              fragments.push(this.makeCode(scope.assignedVariables().join(`,\n${this.tab + TAB}`)));
            }
            fragments.push(this.makeCode(`;\n${(this.spaced ? '\n' : '')}`));
          } else if (fragments.length && post.length) {
            fragments.push(this.makeCode("\n"));
          }
        }
        return fragments.concat(post);
      }

      static wrap(nodes) {
        if (nodes.length === 1 && nodes[0] instanceof Block) {
          return nodes[0];
        }
        return new Block(nodes);
      }

    };

    Block.prototype.children = ['expressions'];

    return Block;

  })();

  exports.Literal = Literal = (function() {
    class Literal extends Base {
      constructor(value1) {
        super();
        this.value = value1;
      }

      assigns(name) {
        return name === this.value;
      }

      compileNode(o) {
        return [this.makeCode(this.value)];
      }

      toString() {
        return ` ${(this.isStatement() ? super.toString() : this.constructor.name)}: ${this.value}`;
      }

    };

    Literal.prototype.shouldCache = NO;

    return Literal;

  })();

  exports.NumberLiteral = NumberLiteral = class NumberLiteral extends Literal {};

  exports.InfinityLiteral = InfinityLiteral = class InfinityLiteral extends NumberLiteral {
    compileNode() {
      return [this.makeCode('2e308')];
    }

  };

  exports.NaNLiteral = NaNLiteral = class NaNLiteral extends NumberLiteral {
    constructor() {
      super('NaN');
    }

    compileNode(o) {
      var code;
      code = [this.makeCode('0/0')];
      if (o.level >= LEVEL_OP) {
        return this.wrapInParentheses(code);
      } else {
        return code;
      }
    }

  };

  exports.StringLiteral = StringLiteral = class StringLiteral extends Literal {};

  exports.RegexLiteral = RegexLiteral = class RegexLiteral extends Literal {};

  exports.PassthroughLiteral = PassthroughLiteral = class PassthroughLiteral extends Literal {};

  exports.IdentifierLiteral = IdentifierLiteral = (function() {
    class IdentifierLiteral extends Literal {
      eachName(iterator) {
        return iterator(this);
      }

    };

    IdentifierLiteral.prototype.isAssignable = YES;

    return IdentifierLiteral;

  })();

  exports.PropertyName = PropertyName = (function() {
    class PropertyName extends Literal {};

    PropertyName.prototype.isAssignable = YES;

    return PropertyName;

  })();

  exports.StatementLiteral = StatementLiteral = (function() {
    class StatementLiteral extends Literal {
      jumps(o) {
        if (this.value === 'break' && !((o != null ? o.loop : void 0) || (o != null ? o.block : void 0))) {
          return this;
        }
        if (this.value === 'continue' && !(o != null ? o.loop : void 0)) {
          return this;
        }
      }

      compileNode(o) {
        return [this.makeCode(`${this.tab}${this.value};`)];
      }

    };

    StatementLiteral.prototype.isStatement = YES;

    StatementLiteral.prototype.makeReturn = THIS;

    return StatementLiteral;

  })();

  exports.ThisLiteral = ThisLiteral = class ThisLiteral extends Literal {
    constructor() {
      super('this');
    }

    compileNode(o) {
      var code, ref1;
      code = ((ref1 = o.scope.method) != null ? ref1.bound : void 0) ? o.scope.method.context : this.value;
      return [this.makeCode(code)];
    }

  };

  exports.UndefinedLiteral = UndefinedLiteral = class UndefinedLiteral extends Literal {
    constructor() {
      super('undefined');
    }

    compileNode(o) {
      return [this.makeCode(o.level >= LEVEL_ACCESS ? '(void 0)' : 'void 0')];
    }

  };

  exports.NullLiteral = NullLiteral = class NullLiteral extends Literal {
    constructor() {
      super('null');
    }

  };

  exports.BooleanLiteral = BooleanLiteral = class BooleanLiteral extends Literal {};

  exports.Return = Return = (function() {
    class Return extends Base {
      constructor(expression1) {
        super();
        this.expression = expression1;
      }

      compileToFragments(o, level) {
        var expr, ref1;
        expr = (ref1 = this.expression) != null ? ref1.makeReturn() : void 0;
        if (expr && !(expr instanceof Return)) {
          return expr.compileToFragments(o, level);
        } else {
          return super.compileToFragments(o, level);
        }
      }

      compileNode(o) {
        var answer;
        answer = [];
        answer.push(this.makeCode(this.tab + `return${(this.expression ? " " : "")}`));
        if (this.expression) {
          answer = answer.concat(this.expression.compileToFragments(o, LEVEL_PAREN));
        }
        answer.push(this.makeCode(";"));
        return answer;
      }

    };

    Return.prototype.children = ['expression'];

    Return.prototype.isStatement = YES;

    Return.prototype.makeReturn = THIS;

    Return.prototype.jumps = THIS;

    return Return;

  })();

  exports.YieldReturn = YieldReturn = class YieldReturn extends Return {
    compileNode(o) {
      if (o.scope.parent == null) {
        this.error('yield can only occur inside functions');
      }
      return super.compileNode(o);
    }

  };

  exports.AwaitReturn = AwaitReturn = class AwaitReturn extends Return {
    compileNode(o) {
      if (o.scope.parent == null) {
        this.error('await can only occur inside functions');
      }
      return super.compileNode(o);
    }

  };

  exports.Value = Value = (function() {
    class Value extends Base {
      constructor(base, props, tag, isDefaultValue = false) {
        if (!props && base instanceof Value) {
          return base;
        }
        super();
        this.base = base;
        this.properties = props || [];
        if (tag) {
          this[tag] = true;
        }
        this.isDefaultValue = isDefaultValue;
        return this;
      }

      add(props) {
        this.properties = this.properties.concat(props);
        return this;
      }

      hasProperties() {
        return !!this.properties.length;
      }

      bareLiteral(type) {
        return !this.properties.length && this.base instanceof type;
      }

      isArray() {
        return this.bareLiteral(Arr);
      }

      isRange() {
        return this.bareLiteral(Range);
      }

      shouldCache() {
        return this.hasProperties() || this.base.shouldCache();
      }

      isAssignable() {
        return this.hasProperties() || this.base.isAssignable();
      }

      isNumber() {
        return this.bareLiteral(NumberLiteral);
      }

      isString() {
        return this.bareLiteral(StringLiteral);
      }

      isRegex() {
        return this.bareLiteral(RegexLiteral);
      }

      isUndefined() {
        return this.bareLiteral(UndefinedLiteral);
      }

      isNull() {
        return this.bareLiteral(NullLiteral);
      }

      isBoolean() {
        return this.bareLiteral(BooleanLiteral);
      }

      isAtomic() {
        var j, len1, node, ref1;
        ref1 = this.properties.concat(this.base);
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          node = ref1[j];
          if (node.soak || node instanceof Call) {
            return false;
          }
        }
        return true;
      }

      isNotCallable() {
        return this.isNumber() || this.isString() || this.isRegex() || this.isArray() || this.isRange() || this.isSplice() || this.isObject() || this.isUndefined() || this.isNull() || this.isBoolean();
      }

      isStatement(o) {
        return !this.properties.length && this.base.isStatement(o);
      }

      assigns(name) {
        return !this.properties.length && this.base.assigns(name);
      }

      jumps(o) {
        return !this.properties.length && this.base.jumps(o);
      }

      isObject(onlyGenerated) {
        if (this.properties.length) {
          return false;
        }
        return (this.base instanceof Obj) && (!onlyGenerated || this.base.generated);
      }

      isSplice() {
        var lastProp, ref1;
        ref1 = this.properties, lastProp = ref1[ref1.length - 1];
        return lastProp instanceof Slice;
      }

      looksStatic(className) {
        var ref1;
        return (this["this"] || this.base instanceof ThisLiteral || this.base.value === className) && this.properties.length === 1 && ((ref1 = this.properties[0].name) != null ? ref1.value : void 0) !== 'prototype';
      }

      unwrap() {
        if (this.properties.length) {
          return this;
        } else {
          return this.base;
        }
      }

      cacheReference(o) {
        var base, bref, name, nref, ref1;
        ref1 = this.properties, name = ref1[ref1.length - 1];
        if (this.properties.length < 2 && !this.base.shouldCache() && !(name != null ? name.shouldCache() : void 0)) {
          return [this, this];
        }
        base = new Value(this.base, this.properties.slice(0, -1));
        if (base.shouldCache()) {
          bref = new IdentifierLiteral(o.scope.freeVariable('base'));
          base = new Value(new Parens(new Assign(bref, base)));
        }
        if (!name) {
          return [base, bref];
        }
        if (name.shouldCache()) {
          nref = new IdentifierLiteral(o.scope.freeVariable('name'));
          name = new Index(new Assign(nref, name.index));
          nref = new Index(nref);
        }
        return [base.add(name), new Value(bref || base.base, [nref || name])];
      }

      compileNode(o) {
        var fragments, j, len1, prop, props;
        this.base.front = this.front;
        props = this.properties;
        fragments = this.base.compileToFragments(o, (props.length ? LEVEL_ACCESS : null));
        if (props.length && SIMPLENUM.test(fragmentsToText(fragments))) {
          fragments.push(this.makeCode('.'));
        }
        for (j = 0, len1 = props.length; j < len1; j++) {
          prop = props[j];
          fragments.push(...prop.compileToFragments(o));
        }
        return fragments;
      }

      unfoldSoak(o) {
        return this.unfoldedSoak != null ? this.unfoldedSoak : this.unfoldedSoak = (() => {
          var fst, i, ifn, j, len1, prop, ref, ref1, snd;
          if (ifn = this.base.unfoldSoak(o)) {
            ifn.body.properties.push(...this.properties);
            return ifn;
          }
          ref1 = this.properties;
          for (i = j = 0, len1 = ref1.length; j < len1; i = ++j) {
            prop = ref1[i];
            if (!prop.soak) {
              continue;
            }
            prop.soak = false;
            fst = new Value(this.base, this.properties.slice(0, i));
            snd = new Value(this.base, this.properties.slice(i));
            if (fst.shouldCache()) {
              ref = new IdentifierLiteral(o.scope.freeVariable('ref'));
              fst = new Parens(new Assign(ref, fst));
              snd.base = ref;
            }
            return new If(new Existence(fst), snd, {
              soak: true
            });
          }
          return false;
        })();
      }

      eachName(iterator) {
        if (this.hasProperties()) {
          return iterator(this);
        } else if (this.base.isAssignable()) {
          return this.base.eachName(iterator);
        } else {
          return this.error('tried to assign to unassignable value');
        }
      }

    };

    Value.prototype.children = ['base', 'properties'];

    return Value;

  })();

  exports.Comment = Comment = (function() {
    class Comment extends Base {
      constructor(comment1) {
        super();
        this.comment = comment1;
      }

      compileNode(o, level) {
        var code, comment;
        comment = this.comment.replace(/^(\s*)#(?=\s)/gm, "$1 *");
        code = `/*${multident(comment, this.tab)}${(indexOf.call(comment, '\n') >= 0 ? `\n${this.tab}` : '')} */`;
        if ((level || o.level) === LEVEL_TOP) {
          code = o.indent + code;
        }
        return [this.makeCode("\n"), this.makeCode(code)];
      }

    };

    Comment.prototype.isStatement = YES;

    Comment.prototype.makeReturn = THIS;

    return Comment;

  })();

  exports.Call = Call = (function() {
    class Call extends Base {
      constructor(variable1, args1 = [], soak1) {
        super();
        this.variable = variable1;
        this.args = args1;
        this.soak = soak1;
        this.isNew = false;
        if (this.variable instanceof Value && this.variable.isNotCallable()) {
          this.variable.error("literal is not a function");
        }
      }

      updateLocationDataIfMissing(locationData) {
        var base, ref1;
        if (this.locationData && this.needsUpdatedStartLocation) {
          this.locationData.first_line = locationData.first_line;
          this.locationData.first_column = locationData.first_column;
          base = ((ref1 = this.variable) != null ? ref1.base : void 0) || this.variable;
          if (base.needsUpdatedStartLocation) {
            this.variable.locationData.first_line = locationData.first_line;
            this.variable.locationData.first_column = locationData.first_column;
            base.updateLocationDataIfMissing(locationData);
          }
          delete this.needsUpdatedStartLocation;
        }
        return super.updateLocationDataIfMissing(locationData);
      }

      newInstance() {
        var base, ref1;
        base = ((ref1 = this.variable) != null ? ref1.base : void 0) || this.variable;
        if (base instanceof Call && !base.isNew) {
          base.newInstance();
        } else {
          this.isNew = true;
        }
        this.needsUpdatedStartLocation = true;
        return this;
      }

      unfoldSoak(o) {
        var call, ifn, j, left, len1, list, ref1, rite;
        if (this.soak) {
          if (this.variable instanceof Super) {
            left = new Literal(this.variable.compile(o));
            rite = new Value(left);
            if (this.variable.accessor == null) {
              this.variable.error("Unsupported reference to 'super'");
            }
          } else {
            if (ifn = unfoldSoak(o, this, 'variable')) {
              return ifn;
            }
            [left, rite] = new Value(this.variable).cacheReference(o);
          }
          rite = new Call(rite, this.args);
          rite.isNew = this.isNew;
          left = new Literal(`typeof ${left.compile(o)} === \"function\"`);
          return new If(left, new Value(rite), {
            soak: true
          });
        }
        call = this;
        list = [];
        while (true) {
          if (call.variable instanceof Call) {
            list.push(call);
            call = call.variable;
            continue;
          }
          if (!(call.variable instanceof Value)) {
            break;
          }
          list.push(call);
          if (!((call = call.variable.base) instanceof Call)) {
            break;
          }
        }
        ref1 = list.reverse();
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          call = ref1[j];
          if (ifn) {
            if (call.variable instanceof Call) {
              call.variable = ifn;
            } else {
              call.variable.base = ifn;
            }
          }
          ifn = unfoldSoak(o, call, 'variable');
        }
        return ifn;
      }

      compileNode(o) {
        var arg, argIndex, compiledArgs, fragments, j, len1, ref1, ref2;
        if ((ref1 = this.variable) != null) {
          ref1.front = this.front;
        }
        compiledArgs = [];
        ref2 = this.args;
        for (argIndex = j = 0, len1 = ref2.length; j < len1; argIndex = ++j) {
          arg = ref2[argIndex];
          if (argIndex) {
            compiledArgs.push(this.makeCode(", "));
          }
          compiledArgs.push(...arg.compileToFragments(o, LEVEL_LIST));
        }
        fragments = [];
        if (this.isNew) {
          if (this.variable instanceof Super) {
            this.variable.error("Unsupported reference to 'super'");
          }
          fragments.push(this.makeCode('new '));
        }
        fragments.push(...this.variable.compileToFragments(o, LEVEL_ACCESS));
        fragments.push(this.makeCode('('), ...compiledArgs, this.makeCode(')'));
        return fragments;
      }

    };

    Call.prototype.children = ['variable', 'args'];

    return Call;

  })();

  exports.SuperCall = SuperCall = (function() {
    class SuperCall extends Call {
      isStatement(o) {
        var ref1;
        return ((ref1 = this.expressions) != null ? ref1.length : void 0) && o.level === LEVEL_TOP;
      }

      compileNode(o) {
        var ref, ref1, replacement, superCall;
        if (!((ref1 = this.expressions) != null ? ref1.length : void 0)) {
          return super.compileNode(o);
        }
        superCall = new Literal(fragmentsToText(super.compileNode(o)));
        replacement = new Block(this.expressions.slice());
        if (o.level > LEVEL_TOP) {
          [superCall, ref] = superCall.cache(o, null, YES);
          replacement.push(ref);
        }
        replacement.unshift(superCall);
        return replacement.compileToFragments(o, o.level === LEVEL_TOP ? o.level : LEVEL_LIST);
      }

    };

    SuperCall.prototype.children = Call.prototype.children.concat(['expressions']);

    return SuperCall;

  })();

  exports.Super = Super = (function() {
    class Super extends Base {
      constructor(accessor) {
        super();
        this.accessor = accessor;
      }

      compileNode(o) {
        var method, name, nref, variable;
        method = o.scope.namedMethod();
        if (!(method != null ? method.isMethod : void 0)) {
          this.error('cannot use super outside of an instance method');
        }
        this.inCtor = !!method.ctor;
        if (!(this.inCtor || (this.accessor != null))) {
          ({name, variable} = method);
          if (name.shouldCache() || (name instanceof Index && name.index.isAssignable())) {
            nref = new IdentifierLiteral(o.scope.parent.freeVariable('name'));
            name.index = new Assign(nref, name.index);
          }
          this.accessor = nref != null ? new Index(nref) : name;
        }
        return (new Value(new Literal('super'), this.accessor ? [this.accessor] : [])).compileToFragments(o);
      }

    };

    Super.prototype.children = ['accessor'];

    return Super;

  })();

  exports.RegexWithInterpolations = RegexWithInterpolations = class RegexWithInterpolations extends Call {
    constructor(args = []) {
      super(new Value(new IdentifierLiteral('RegExp')), args, false);
    }

  };

  exports.TaggedTemplateCall = TaggedTemplateCall = class TaggedTemplateCall extends Call {
    constructor(variable, arg, soak) {
      if (arg instanceof StringLiteral) {
        arg = new StringWithInterpolations(Block.wrap([new Value(arg)]));
      }
      super(variable, [arg], soak);
    }

    compileNode(o) {
      return this.variable.compileToFragments(o, LEVEL_ACCESS).concat(this.args[0].compileToFragments(o, LEVEL_LIST));
    }

  };

  exports.Extends = Extends = (function() {
    class Extends extends Base {
      constructor(child1, parent1) {
        super();
        this.child = child1;
        this.parent = parent1;
      }

      compileToFragments(o) {
        return new Call(new Value(new Literal(utility('extend', o))), [this.child, this.parent]).compileToFragments(o);
      }

    };

    Extends.prototype.children = ['child', 'parent'];

    return Extends;

  })();

  exports.Access = Access = (function() {
    class Access extends Base {
      constructor(name1, tag) {
        super();
        this.name = name1;
        this.soak = tag === 'soak';
      }

      compileToFragments(o) {
        var name, node, ref1;
        name = this.name.compileToFragments(o);
        node = this.name.unwrap();
        if (node instanceof PropertyName) {
          if (ref1 = node.value, indexOf.call(JS_FORBIDDEN, ref1) >= 0) {
            return [this.makeCode('["'), ...name, this.makeCode('"]')];
          } else {
            return [this.makeCode('.'), ...name];
          }
        } else {
          return [this.makeCode('['), ...name, this.makeCode(']')];
        }
      }

    };

    Access.prototype.children = ['name'];

    Access.prototype.shouldCache = NO;

    return Access;

  })();

  exports.Index = Index = (function() {
    class Index extends Base {
      constructor(index1) {
        super();
        this.index = index1;
      }

      compileToFragments(o) {
        return [].concat(this.makeCode("["), this.index.compileToFragments(o, LEVEL_PAREN), this.makeCode("]"));
      }

      shouldCache() {
        return this.index.shouldCache();
      }

    };

    Index.prototype.children = ['index'];

    return Index;

  })();

  exports.Range = Range = (function() {
    class Range extends Base {
      constructor(from1, to1, tag) {
        super();
        this.from = from1;
        this.to = to1;
        this.exclusive = tag === 'exclusive';
        this.equals = this.exclusive ? '' : '=';
      }

      compileVariables(o) {
        var shouldCache, step;
        o = merge(o, {
          top: true
        });
        shouldCache = del(o, 'shouldCache');
        [this.fromC, this.fromVar] = this.cacheToCodeFragments(this.from.cache(o, LEVEL_LIST, shouldCache));
        [this.toC, this.toVar] = this.cacheToCodeFragments(this.to.cache(o, LEVEL_LIST, shouldCache));
        if (step = del(o, 'step')) {
          [this.step, this.stepVar] = this.cacheToCodeFragments(step.cache(o, LEVEL_LIST, shouldCache));
        }
        this.fromNum = this.from.isNumber() ? Number(this.fromVar) : null;
        this.toNum = this.to.isNumber() ? Number(this.toVar) : null;
        return this.stepNum = (step != null ? step.isNumber() : void 0) ? Number(this.stepVar) : null;
      }

      compileNode(o) {
        var cond, condPart, from, gt, idx, idxName, known, lt, namedIndex, stepPart, to, varPart;
        if (!this.fromVar) {
          this.compileVariables(o);
        }
        if (!o.index) {
          return this.compileArray(o);
        }
        known = (this.fromNum != null) && (this.toNum != null);
        idx = del(o, 'index');
        idxName = del(o, 'name');
        namedIndex = idxName && idxName !== idx;
        varPart = `${idx} = ${this.fromC}`;
        if (this.toC !== this.toVar) {
          varPart += `, ${this.toC}`;
        }
        if (this.step !== this.stepVar) {
          varPart += `, ${this.step}`;
        }
        [lt, gt] = [`${idx} <${this.equals}`, `${idx} >${this.equals}`];
        condPart = this.stepNum != null ? this.stepNum > 0 ? `${lt} ${this.toVar}` : `${gt} ${this.toVar}` : known ? ([from, to] = [this.fromNum, this.toNum], from <= to ? `${lt} ${to}` : `${gt} ${to}`) : (cond = this.stepVar ? `${this.stepVar} > 0` : `${this.fromVar} <= ${this.toVar}`, `${cond} ? ${lt} ${this.toVar} : ${gt} ${this.toVar}`);
        stepPart = this.stepVar ? `${idx} += ${this.stepVar}` : known ? namedIndex ? from <= to ? `++${idx}` : `--${idx}` : from <= to ? `${idx}++` : `${idx}--` : namedIndex ? `${cond} ? ++${idx} : --${idx}` : `${cond} ? ${idx}++ : ${idx}--`;
        if (namedIndex) {
          varPart = `${idxName} = ${varPart}`;
        }
        if (namedIndex) {
          stepPart = `${idxName} = ${stepPart}`;
        }
        return [this.makeCode(`${varPart}; ${condPart}; ${stepPart}`)];
      }

      compileArray(o) {
        var args, body, cond, hasArgs, i, idt, j, known, post, pre, range, ref1, ref2, result, results, vars;
        known = (this.fromNum != null) && (this.toNum != null);
        if (known && Math.abs(this.fromNum - this.toNum) <= 20) {
          range = (function() {
            results = [];
            for (var j = ref1 = this.fromNum, ref2 = this.toNum; ref1 <= ref2 ? j <= ref2 : j >= ref2; ref1 <= ref2 ? j++ : j--){ results.push(j); }
            return results;
          }).apply(this);
          if (this.exclusive) {
            range.pop();
          }
          return [this.makeCode(`[${range.join(', ')}]`)];
        }
        idt = this.tab + TAB;
        i = o.scope.freeVariable('i', {
          single: true
        });
        result = o.scope.freeVariable('results');
        pre = `\n${idt}${result} = [];`;
        if (known) {
          o.index = i;
          body = fragmentsToText(this.compileNode(o));
        } else {
          vars = `${i} = ${this.fromC}` + (this.toC !== this.toVar ? `, ${this.toC}` : '');
          cond = `${this.fromVar} <= ${this.toVar}`;
          body = `var ${vars}; ${cond} ? ${i} <${this.equals} ${this.toVar} : ${i} >${this.equals} ${this.toVar}; ${cond} ? ${i}++ : ${i}--`;
        }
        post = `{ ${result}.push(${i}); }\n${idt}return ${result};\n${o.indent}`;
        hasArgs = function(node) {
          return node != null ? node.contains(isLiteralArguments) : void 0;
        };
        if (hasArgs(this.from) || hasArgs(this.to)) {
          args = ', arguments';
        }
        return [this.makeCode(`(function() {${pre}\n${idt}for (${body})${post}}).apply(this${args != null ? args : ''})`)];
      }

    };

    Range.prototype.children = ['from', 'to'];

    return Range;

  })();

  exports.Slice = Slice = (function() {
    class Slice extends Base {
      constructor(range1) {
        super();
        this.range = range1;
      }

      compileNode(o) {
        var compiled, compiledText, from, fromCompiled, to, toStr;
        ({to, from} = this.range);
        fromCompiled = from && from.compileToFragments(o, LEVEL_PAREN) || [this.makeCode('0')];
        if (to) {
          compiled = to.compileToFragments(o, LEVEL_PAREN);
          compiledText = fragmentsToText(compiled);
          if (!(!this.range.exclusive && +compiledText === -1)) {
            toStr = ', ' + (this.range.exclusive ? compiledText : to.isNumber() ? `${+compiledText + 1}` : (compiled = to.compileToFragments(o, LEVEL_ACCESS), `+${fragmentsToText(compiled)} + 1 || 9e9`));
          }
        }
        return [this.makeCode(`.slice(${fragmentsToText(fromCompiled)}${toStr || ''})`)];
      }

    };

    Slice.prototype.children = ['range'];

    return Slice;

  })();

  exports.Obj = Obj = (function() {
    class Obj extends Base {
      constructor(props, generated = false, lhs1 = false) {
        super();
        this.generated = generated;
        this.lhs = lhs1;
        this.objects = this.properties = props || [];
      }

      isAssignable() {
        var j, len1, message, prop, ref1;
        ref1 = this.properties;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          prop = ref1[j];
          message = isUnassignable(prop.unwrapAll().value);
          if (message) {
            prop.error(message);
          }
          if (prop instanceof Assign && prop.context === 'object') {
            prop = prop.value;
          }
          if (!prop.isAssignable()) {
            return false;
          }
        }
        return true;
      }

      shouldCache() {
        return !this.isAssignable();
      }

      compileNode(o) {
        var answer, i, idt, indent, isCompact, j, join, k, key, l, lastNoncom, len1, len2, len3, node, prop, props, ref1, value;
        props = this.properties;
        if (this.generated) {
          for (j = 0, len1 = props.length; j < len1; j++) {
            node = props[j];
            if (node instanceof Value) {
              node.error('cannot have an implicit value in an implicit object');
            }
          }
        }
        idt = o.indent += TAB;
        lastNoncom = this.lastNonComment(this.properties);
        isCompact = true;
        ref1 = this.properties;
        for (k = 0, len2 = ref1.length; k < len2; k++) {
          prop = ref1[k];
          if (prop instanceof Comment || (prop instanceof Assign && prop.context === 'object')) {
            isCompact = false;
          }
        }
        answer = [];
        answer.push(this.makeCode(`{${(isCompact ? '' : '\n')}`));
        for (i = l = 0, len3 = props.length; l < len3; i = ++l) {
          prop = props[i];
          join = i === props.length - 1 ? '' : isCompact ? ', ' : prop === lastNoncom || prop instanceof Comment ? '\n' : ',\n';
          indent = isCompact || prop instanceof Comment ? '' : idt;
          key = prop instanceof Assign && prop.context === 'object' ? prop.variable : prop instanceof Assign ? (!this.lhs ? prop.operatorToken.error(`unexpected ${prop.operatorToken.value}`) : void 0, prop.variable) : !(prop instanceof Comment) ? prop : void 0;
          if (key instanceof Value && key.hasProperties()) {
            if (prop.context === 'object' || !key["this"]) {
              key.error('invalid object key');
            }
            key = key.properties[0].name;
            prop = new Assign(key, prop, 'object');
          }
          if (key === prop) {
            if (prop.shouldCache()) {
              [key, value] = prop.base.cache(o);
              if (key instanceof IdentifierLiteral) {
                key = new PropertyName(key.value);
              }
              prop = new Assign(key, value, 'object');
            } else if (!(typeof prop.bareLiteral === "function" ? prop.bareLiteral(IdentifierLiteral) : void 0)) {
              prop = new Assign(prop, prop, 'object');
            }
          }
          if (indent) {
            answer.push(this.makeCode(indent));
          }
          answer.push(...prop.compileToFragments(o, LEVEL_TOP));
          if (join) {
            answer.push(this.makeCode(join));
          }
        }
        answer.push(this.makeCode(`${(isCompact ? '' : `\n${this.tab}`)}}`));
        if (this.front) {
          return this.wrapInParentheses(answer);
        } else {
          return answer;
        }
      }

      assigns(name) {
        var j, len1, prop, ref1;
        ref1 = this.properties;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          prop = ref1[j];
          if (prop.assigns(name)) {
            return true;
          }
        }
        return false;
      }

      eachName(iterator) {
        var j, len1, prop, ref1, results;
        ref1 = this.properties;
        results = [];
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          prop = ref1[j];
          if (prop instanceof Assign && prop.context === 'object') {
            prop = prop.value;
          }
          prop = prop.unwrapAll();
          if (prop.eachName != null) {
            results.push(prop.eachName(iterator));
          } else {
            results.push(void 0);
          }
        }
        return results;
      }

    };

    Obj.prototype.children = ['properties'];

    return Obj;

  })();

  exports.Arr = Arr = (function() {
    class Arr extends Base {
      constructor(objs, lhs1 = false) {
        super();
        this.lhs = lhs1;
        this.objects = objs || [];
      }

      isAssignable() {
        var i, j, len1, obj, ref1;
        if (!this.objects.length) {
          return false;
        }
        ref1 = this.objects;
        for (i = j = 0, len1 = ref1.length; j < len1; i = ++j) {
          obj = ref1[i];
          if (obj instanceof Splat && i + 1 !== this.objects.length) {
            return false;
          }
          if (!(obj.isAssignable() && (!obj.isAtomic || obj.isAtomic()))) {
            return false;
          }
        }
        return true;
      }

      shouldCache() {
        return !this.isAssignable();
      }

      compileNode(o) {
        var answer, compiledObjs, fragments, index, j, k, len1, len2, obj, ref1, unwrappedObj;
        if (!this.objects.length) {
          return [this.makeCode('[]')];
        }
        o.indent += TAB;
        answer = [];
        if (this.lhs) {
          ref1 = this.objects;
          for (j = 0, len1 = ref1.length; j < len1; j++) {
            obj = ref1[j];
            unwrappedObj = obj.unwrapAll();
            if (unwrappedObj instanceof Arr || unwrappedObj instanceof Obj) {
              unwrappedObj.lhs = true;
            }
          }
        }
        compiledObjs = (function() {
          var k, len2, ref2, results;
          ref2 = this.objects;
          results = [];
          for (k = 0, len2 = ref2.length; k < len2; k++) {
            obj = ref2[k];
            results.push(obj.compileToFragments(o, LEVEL_LIST));
          }
          return results;
        }).call(this);
        for (index = k = 0, len2 = compiledObjs.length; k < len2; index = ++k) {
          fragments = compiledObjs[index];
          if (index) {
            answer.push(this.makeCode(", "));
          }
          answer.push(...fragments);
        }
        if (fragmentsToText(answer).indexOf('\n') >= 0) {
          answer.unshift(this.makeCode(`[\n${o.indent}`));
          answer.push(this.makeCode(`\n${this.tab}]`));
        } else {
          answer.unshift(this.makeCode("["));
          answer.push(this.makeCode("]"));
        }
        return answer;
      }

      assigns(name) {
        var j, len1, obj, ref1;
        ref1 = this.objects;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          obj = ref1[j];
          if (obj.assigns(name)) {
            return true;
          }
        }
        return false;
      }

      eachName(iterator) {
        var j, len1, obj, ref1, results;
        ref1 = this.objects;
        results = [];
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          obj = ref1[j];
          obj = obj.unwrapAll();
          results.push(obj.eachName(iterator));
        }
        return results;
      }

    };

    Arr.prototype.children = ['objects'];

    return Arr;

  })();

  exports.Class = Class = (function() {
    class Class extends Base {
      constructor(variable1, parent1, body1 = new Block) {
        super();
        this.variable = variable1;
        this.parent = parent1;
        this.body = body1;
      }

      compileNode(o) {
        var assign, executableBody, parentName, result;
        this.name = this.determineName();
        executableBody = this.walkBody();
        if (this.parent instanceof Value && !this.parent.hasProperties()) {
          parentName = this.parent.base.value;
        }
        this.hasNameClash = (this.name != null) && this.name === parentName;
        if (executableBody || this.hasNameClash) {
          this.compileNode = this.compileClassDeclaration;
          result = new ExecutableClassBody(this, executableBody).compileToFragments(o);
          this.compileNode = this.constructor.prototype.compileNode;
        } else {
          result = this.compileClassDeclaration(o);
          if ((this.name == null) && o.level === LEVEL_TOP) {
            result = this.wrapInParentheses(result);
          }
        }
        if (this.variable) {
          assign = new Assign(this.variable, new Literal(''), null, {moduleDeclaration: this.moduleDeclaration});
          return [...assign.compileToFragments(o), ...result];
        } else {
          return result;
        }
      }

      compileClassDeclaration(o) {
        var ref1, result;
        if (this.externalCtor || this.boundMethods.length) {
          if (this.ctor == null) {
            this.ctor = this.makeDefaultConstructor();
          }
        }
        if ((ref1 = this.ctor) != null) {
          ref1.noReturn = true;
        }
        if (this.boundMethods.length) {
          this.proxyBoundMethods(o);
        }
        o.indent += TAB;
        result = [];
        result.push(this.makeCode("class "));
        if (this.name) {
          result.push(this.makeCode(`${this.name} `));
        }
        if (this.parent) {
          result.push(this.makeCode('extends '), ...this.parent.compileToFragments(o), this.makeCode(' '));
        }
        result.push(this.makeCode('{'));
        if (!this.body.isEmpty()) {
          this.body.spaced = true;
          result.push(this.makeCode('\n'));
          result.push(...this.body.compileToFragments(o, LEVEL_TOP));
          result.push(this.makeCode(`\n${this.tab}`));
        }
        result.push(this.makeCode('}'));
        return result;
      }

      determineName() {
        var message, name, node, ref1, tail;
        if (!this.variable) {
          return null;
        }
        ref1 = this.variable.properties, tail = ref1[ref1.length - 1];
        node = tail ? tail instanceof Access && tail.name : this.variable.base;
        if (!(node instanceof IdentifierLiteral || node instanceof PropertyName)) {
          return null;
        }
        name = node.value;
        if (!tail) {
          message = isUnassignable(name);
          if (message) {
            this.variable.error(message);
          }
        }
        if (indexOf.call(JS_FORBIDDEN, name) >= 0) {
          return `_${name}`;
        } else {
          return name;
        }
      }

      walkBody() {
        var assign, end, executableBody, expression, expressions, exprs, i, initializer, initializerExpression, j, k, len1, len2, method, properties, pushSlice, ref1, start;
        this.ctor = null;
        this.boundMethods = [];
        executableBody = null;
        initializer = [];
        ({expressions} = this.body);
        i = 0;
        ref1 = expressions.slice();
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          expression = ref1[j];
          if (expression instanceof Value && expression.isObject(true)) {
            ({properties} = expression.base);
            exprs = [];
            end = 0;
            start = 0;
            pushSlice = function() {
              if (end > start) {
                return exprs.push(new Value(new Obj(properties.slice(start, end), true)));
              }
            };
            while (assign = properties[end]) {
              if (initializerExpression = this.addInitializerExpression(assign)) {
                pushSlice();
                exprs.push(initializerExpression);
                initializer.push(initializerExpression);
                start = end + 1;
              } else if (initializer[initializer.length - 1] instanceof Comment) {
                exprs.pop();
                initializer.pop();
                start--;
              }
              end++;
            }
            pushSlice();
            [].splice.apply(expressions, [i, i - i + 1].concat(exprs)), exprs;
            i += exprs.length;
          } else {
            if (initializerExpression = this.addInitializerExpression(expression)) {
              initializer.push(initializerExpression);
              expressions[i] = initializerExpression;
            } else if (initializer[initializer.length - 1] instanceof Comment) {
              initializer.pop();
            }
            i += 1;
          }
        }
        for (k = 0, len2 = initializer.length; k < len2; k++) {
          method = initializer[k];
          if (method instanceof Code) {
            if (method.ctor) {
              if (this.ctor) {
                method.error('Cannot define more than one constructor in a class');
              }
              this.ctor = method;
            } else if (method.bound && method.isStatic) {
              method.context = this.name;
            } else if (method.bound) {
              this.boundMethods.push(method.name);
              method.bound = false;
            }
          }
        }
        if (initializer.length !== expressions.length) {
          this.body.expressions = (function() {
            var l, len3, results;
            results = [];
            for (l = 0, len3 = initializer.length; l < len3; l++) {
              expression = initializer[l];
              results.push(expression.hoist());
            }
            return results;
          })();
          return new Block(expressions);
        }
      }

      addInitializerExpression(node) {
        switch (false) {
          case !(node instanceof Comment):
            return node;
          case !this.validInitializerMethod(node):
            return this.addInitializerMethod(node);
          default:
            return null;
        }
      }

      validInitializerMethod(node) {
        if (!(node instanceof Assign && node.value instanceof Code)) {
          return false;
        }
        if (node.context === 'object' && !node.variable.hasProperties()) {
          return true;
        }
        return node.variable.looksStatic(this.name) && (this.name || !node.value.bound);
      }

      addInitializerMethod(assign) {
        var method, methodName, variable;
        ({
          variable,
          value: method
        } = assign);
        method.isMethod = true;
        method.isStatic = variable.looksStatic(this.name);
        if (method.isStatic) {
          method.name = variable.properties[0];
        } else {
          methodName = variable.base;
          method.name = new (methodName.shouldCache() ? Index : Access)(methodName);
          method.name.updateLocationDataIfMissing(methodName.locationData);
          if (methodName.value === 'constructor') {
            method.ctor = (this.parent ? 'derived' : 'base');
          }
          if (method.bound && method.ctor) {
            method.error('Cannot define a constructor as a bound function');
          }
        }
        return method;
      }

      makeDefaultConstructor() {
        var applyArgs, applyCtor, ctor;
        ctor = this.addInitializerMethod(new Assign(new Value(new PropertyName('constructor')), new Code));
        this.body.unshift(ctor);
        if (this.parent) {
          ctor.body.push(new SuperCall(new Super, [new Splat(new IdentifierLiteral('arguments'))]));
        }
        if (this.externalCtor) {
          applyCtor = new Value(this.externalCtor, [new Access(new PropertyName('apply'))]);
          applyArgs = [new ThisLiteral, new IdentifierLiteral('arguments')];
          ctor.body.push(new Call(applyCtor, applyArgs));
          ctor.body.makeReturn();
        }
        return ctor;
      }

      proxyBoundMethods(o) {
        var name;
        this.ctor.thisAssignments = (function() {
          var j, ref1, results;
          ref1 = this.boundMethods;
          results = [];
          for (j = ref1.length - 1; j >= 0; j += -1) {
            name = ref1[j];
            name = new Value(new ThisLiteral, [name]).compile(o);
            results.push(new Literal(`${name} = ${utility('bind', o)}(${name}, this)`));
          }
          return results;
        }).call(this);
        return null;
      }

    };

    Class.prototype.children = ['variable', 'parent', 'body'];

    return Class;

  })();

  exports.ExecutableClassBody = ExecutableClassBody = (function() {
    class ExecutableClassBody extends Base {
      constructor(_class, body1 = new Block) {
        super();
        this["class"] = _class;
        this.body = body1;
      }

      compileNode(o) {
        var args, argumentsNode, directives, externalCtor, ident, jumpNode, klass, params, parent, ref1, wrapper;
        if (jumpNode = this.body.jumps()) {
          jumpNode.error('Class bodies cannot contain pure statements');
        }
        if (argumentsNode = this.body.contains(isLiteralArguments)) {
          argumentsNode.error("Class bodies shouldn't reference arguments");
        }
        this.name = (ref1 = this["class"].name) != null ? ref1 : this.defaultClassVariableName;
        directives = this.walkBody();
        this.setContext();
        ident = new IdentifierLiteral(this.name);
        params = [];
        args = [];
        wrapper = new Code(params, this.body);
        klass = new Parens(new Call(wrapper, args));
        this.body.spaced = true;
        o.classScope = wrapper.makeScope(o.scope);
        if (this["class"].hasNameClash) {
          parent = new IdentifierLiteral(o.classScope.freeVariable('superClass'));
          wrapper.params.push(new Param(parent));
          args.push(this["class"].parent);
          this["class"].parent = parent;
        }
        if (this.externalCtor) {
          externalCtor = new IdentifierLiteral(o.classScope.freeVariable('ctor', {
            reserve: false
          }));
          this["class"].externalCtor = externalCtor;
          this.externalCtor.variable.base = externalCtor;
        }
        if (this.name !== this["class"].name) {
          this.body.expressions.unshift(new Assign(new IdentifierLiteral(this.name), this["class"]));
        } else {
          this.body.expressions.unshift(this["class"]);
        }
        this.body.expressions.unshift(...directives);
        this.body.push(ident);
        return klass.compileToFragments(o);
      }

      walkBody() {
        var directives, expr, index;
        directives = [];
        index = 0;
        while (expr = this.body.expressions[index]) {
          if (!(expr instanceof Comment || expr instanceof Value && expr.isString())) {
            break;
          }
          if (expr.hoisted) {
            index++;
          } else {
            directives.push(...this.body.expressions.splice(index, 1));
          }
        }
        this.traverseChildren(false, (child) => {
          var cont, i, j, len1, node, ref1;
          if (child instanceof Class || child instanceof HoistTarget) {
            return false;
          }
          cont = true;
          if (child instanceof Block) {
            ref1 = child.expressions;
            for (i = j = 0, len1 = ref1.length; j < len1; i = ++j) {
              node = ref1[i];
              if (node instanceof Value && node.isObject(true)) {
                cont = false;
                child.expressions[i] = this.addProperties(node.base.properties);
              } else if (node instanceof Assign && node.variable.looksStatic(this.name)) {
                node.value.isStatic = true;
              }
            }
            child.expressions = flatten(child.expressions);
          }
          return cont;
        });
        return directives;
      }

      setContext() {
        return this.body.traverseChildren(false, (node) => {
          if (node instanceof ThisLiteral) {
            return node.value = this.name;
          } else if (node instanceof Code && node.bound) {
            return node.context = this.name;
          }
        });
      }

      addProperties(assigns) {
        var assign, base, name, prototype, result, value, variable;
        result = (function() {
          var j, len1, results;
          results = [];
          for (j = 0, len1 = assigns.length; j < len1; j++) {
            assign = assigns[j];
            variable = assign.variable;
            base = variable != null ? variable.base : void 0;
            value = assign.value;
            delete assign.context;
            if (assign instanceof Comment) {

            } else if (base.value === 'constructor') {
              if (value instanceof Code) {
                base.error('constructors must be defined at the top level of a class body');
              }
              assign = this.externalCtor = new Assign(new Value, value);
            } else if (!assign.variable["this"]) {
              name = new (base.shouldCache() ? Index : Access)(base);
              prototype = new Access(new PropertyName('prototype'));
              variable = new Value(new ThisLiteral(), [prototype, name]);
              assign.variable = variable;
            } else if (assign.value instanceof Code) {
              assign.value.isStatic = true;
            }
            results.push(assign);
          }
          return results;
        }).call(this);
        return compact(result);
      }

    };

    ExecutableClassBody.prototype.children = ['class', 'body'];

    ExecutableClassBody.prototype.defaultClassVariableName = '_Class';

    return ExecutableClassBody;

  })();

  exports.ModuleDeclaration = ModuleDeclaration = (function() {
    class ModuleDeclaration extends Base {
      constructor(clause, source1) {
        super();
        this.clause = clause;
        this.source = source1;
        this.checkSource();
      }

      checkSource() {
        if ((this.source != null) && this.source instanceof StringWithInterpolations) {
          return this.source.error('the name of the module to be imported from must be an uninterpolated string');
        }
      }

      checkScope(o, moduleDeclarationType) {
        if (o.indent.length !== 0) {
          return this.error(`${moduleDeclarationType} statements must be at top-level scope`);
        }
      }

    };

    ModuleDeclaration.prototype.children = ['clause', 'source'];

    ModuleDeclaration.prototype.isStatement = YES;

    ModuleDeclaration.prototype.jumps = THIS;

    ModuleDeclaration.prototype.makeReturn = THIS;

    return ModuleDeclaration;

  })();

  exports.ImportDeclaration = ImportDeclaration = class ImportDeclaration extends ModuleDeclaration {
    compileNode(o) {
      var code, ref1;
      this.checkScope(o, 'import');
      o.importedSymbols = [];
      code = [];
      code.push(this.makeCode(`${this.tab}import `));
      if (this.clause != null) {
        code.push(...this.clause.compileNode(o));
      }
      if (((ref1 = this.source) != null ? ref1.value : void 0) != null) {
        if (this.clause !== null) {
          code.push(this.makeCode(' from '));
        }
        code.push(this.makeCode(this.source.value));
      }
      code.push(this.makeCode(';'));
      return code;
    }

  };

  exports.ImportClause = ImportClause = (function() {
    class ImportClause extends Base {
      constructor(defaultBinding, namedImports) {
        super();
        this.defaultBinding = defaultBinding;
        this.namedImports = namedImports;
      }

      compileNode(o) {
        var code;
        code = [];
        if (this.defaultBinding != null) {
          code.push(...this.defaultBinding.compileNode(o));
          if (this.namedImports != null) {
            code.push(this.makeCode(', '));
          }
        }
        if (this.namedImports != null) {
          code.push(...this.namedImports.compileNode(o));
        }
        return code;
      }

    };

    ImportClause.prototype.children = ['defaultBinding', 'namedImports'];

    return ImportClause;

  })();

  exports.ExportDeclaration = ExportDeclaration = class ExportDeclaration extends ModuleDeclaration {
    compileNode(o) {
      var code, ref1;
      this.checkScope(o, 'export');
      code = [];
      code.push(this.makeCode(`${this.tab}export `));
      if (this instanceof ExportDefaultDeclaration) {
        code.push(this.makeCode('default '));
      }
      if (!(this instanceof ExportDefaultDeclaration) && (this.clause instanceof Assign || this.clause instanceof Class)) {
        if (this.clause instanceof Class && !this.clause.variable) {
          this.clause.error('anonymous classes cannot be exported');
        }
        code.push(this.makeCode('var '));
        this.clause.moduleDeclaration = 'export';
      }
      if ((this.clause.body != null) && this.clause.body instanceof Block) {
        code = code.concat(this.clause.compileToFragments(o, LEVEL_TOP));
      } else {
        code = code.concat(this.clause.compileNode(o));
      }
      if (((ref1 = this.source) != null ? ref1.value : void 0) != null) {
        code.push(this.makeCode(` from ${this.source.value}`));
      }
      code.push(this.makeCode(';'));
      return code;
    }

  };

  exports.ExportNamedDeclaration = ExportNamedDeclaration = class ExportNamedDeclaration extends ExportDeclaration {};

  exports.ExportDefaultDeclaration = ExportDefaultDeclaration = class ExportDefaultDeclaration extends ExportDeclaration {};

  exports.ExportAllDeclaration = ExportAllDeclaration = class ExportAllDeclaration extends ExportDeclaration {};

  exports.ModuleSpecifierList = ModuleSpecifierList = (function() {
    class ModuleSpecifierList extends Base {
      constructor(specifiers) {
        super();
        this.specifiers = specifiers;
      }

      compileNode(o) {
        var code, compiledList, fragments, index, j, len1, specifier;
        code = [];
        o.indent += TAB;
        compiledList = (function() {
          var j, len1, ref1, results;
          ref1 = this.specifiers;
          results = [];
          for (j = 0, len1 = ref1.length; j < len1; j++) {
            specifier = ref1[j];
            results.push(specifier.compileToFragments(o, LEVEL_LIST));
          }
          return results;
        }).call(this);
        if (this.specifiers.length !== 0) {
          code.push(this.makeCode(`{\n${o.indent}`));
          for (index = j = 0, len1 = compiledList.length; j < len1; index = ++j) {
            fragments = compiledList[index];
            if (index) {
              code.push(this.makeCode(`,\n${o.indent}`));
            }
            code.push(...fragments);
          }
          code.push(this.makeCode("\n}"));
        } else {
          code.push(this.makeCode('{}'));
        }
        return code;
      }

    };

    ModuleSpecifierList.prototype.children = ['specifiers'];

    return ModuleSpecifierList;

  })();

  exports.ImportSpecifierList = ImportSpecifierList = class ImportSpecifierList extends ModuleSpecifierList {};

  exports.ExportSpecifierList = ExportSpecifierList = class ExportSpecifierList extends ModuleSpecifierList {};

  exports.ModuleSpecifier = ModuleSpecifier = (function() {
    class ModuleSpecifier extends Base {
      constructor(original, alias, moduleDeclarationType1) {
        super();
        this.original = original;
        this.alias = alias;
        this.moduleDeclarationType = moduleDeclarationType1;
        this.identifier = this.alias != null ? this.alias.value : this.original.value;
      }

      compileNode(o) {
        var code;
        o.scope.find(this.identifier, this.moduleDeclarationType);
        code = [];
        code.push(this.makeCode(this.original.value));
        if (this.alias != null) {
          code.push(this.makeCode(` as ${this.alias.value}`));
        }
        return code;
      }

    };

    ModuleSpecifier.prototype.children = ['original', 'alias'];

    return ModuleSpecifier;

  })();

  exports.ImportSpecifier = ImportSpecifier = class ImportSpecifier extends ModuleSpecifier {
    constructor(imported, local) {
      super(imported, local, 'import');
    }

    compileNode(o) {
      var ref1;
      if ((ref1 = this.identifier, indexOf.call(o.importedSymbols, ref1) >= 0) || o.scope.check(this.identifier)) {
        this.error(`'${this.identifier}' has already been declared`);
      } else {
        o.importedSymbols.push(this.identifier);
      }
      return super.compileNode(o);
    }

  };

  exports.ImportDefaultSpecifier = ImportDefaultSpecifier = class ImportDefaultSpecifier extends ImportSpecifier {};

  exports.ImportNamespaceSpecifier = ImportNamespaceSpecifier = class ImportNamespaceSpecifier extends ImportSpecifier {};

  exports.ExportSpecifier = ExportSpecifier = class ExportSpecifier extends ModuleSpecifier {
    constructor(local, exported) {
      super(local, exported, 'export');
    }

  };

  exports.Assign = Assign = (function() {
    class Assign extends Base {
      constructor(variable1, value1, context1, options = {}) {
        super();
        this.variable = variable1;
        this.value = value1;
        this.context = context1;
        ({param: this.param, subpattern: this.subpattern, operatorToken: this.operatorToken, moduleDeclaration: this.moduleDeclaration} = options);
      }

      isStatement(o) {
        return (o != null ? o.level : void 0) === LEVEL_TOP && (this.context != null) && (this.moduleDeclaration || indexOf.call(this.context, "?") >= 0);
      }

      checkAssignability(o, varBase) {
        if (Object.prototype.hasOwnProperty.call(o.scope.positions, varBase.value) && o.scope.variables[o.scope.positions[varBase.value]].type === 'import') {
          return varBase.error(`'${varBase.value}' is read-only`);
        }
      }

      assigns(name) {
        return this[this.context === 'object' ? 'value' : 'variable'].assigns(name);
      }

      unfoldSoak(o) {
        return unfoldSoak(o, this, 'variable');
      }

      compileNode(o) {
        var answer, compiledName, isValue, j, name, properties, prototype, ref1, ref2, ref3, ref4, ref5, ref6, val, varBase;
        isValue = this.variable instanceof Value;
        if (isValue) {
          this.variable.param = this.param;
          if (this.variable.isArray() || this.variable.isObject()) {
            this.variable.base.lhs = true;
            if (!this.variable.isAssignable()) {
              return this.compileDestructuring(o);
            }
          }
          if (this.variable.isSplice()) {
            return this.compileSplice(o);
          }
          if ((ref1 = this.context) === '||=' || ref1 === '&&=' || ref1 === '?=') {
            return this.compileConditional(o);
          }
          if ((ref2 = this.context) === '**=' || ref2 === '//=' || ref2 === '%%=') {
            return this.compileSpecialMath(o);
          }
        }
        if (!this.context) {
          varBase = this.variable.unwrapAll();
          if (!varBase.isAssignable()) {
            this.variable.error(`'${this.variable.compile(o)}' can't be assigned`);
          }
          varBase.eachName((name) => {
            var message;
            if (typeof name.hasProperties === "function" ? name.hasProperties() : void 0) {
              return;
            }
            message = isUnassignable(name.value);
            if (message) {
              name.error(message);
            }
            this.checkAssignability(o, name);
            if (this.moduleDeclaration) {
              return o.scope.add(name.value, this.moduleDeclaration);
            } else {
              return o.scope.find(name.value);
            }
          });
        }
        if (this.value instanceof Code) {
          if (this.value.isStatic) {
            this.value.name = this.variable.properties[0];
          } else if (((ref3 = this.variable.properties) != null ? ref3.length : void 0) >= 2) {
            ref4 = this.variable.properties, properties = 3 <= ref4.length ? slice.call(ref4, 0, j = ref4.length - 2) : (j = 0, []), prototype = ref4[j++], name = ref4[j++];
            if (((ref5 = prototype.name) != null ? ref5.value : void 0) === 'prototype') {
              this.value.name = name;
            }
          }
        }
        val = this.value.compileToFragments(o, LEVEL_LIST);
        compiledName = this.variable.compileToFragments(o, LEVEL_LIST);
        if (this.context === 'object') {
          if (this.variable.shouldCache()) {
            compiledName.unshift(this.makeCode('['));
            compiledName.push(this.makeCode(']'));
          } else if (ref6 = fragmentsToText(compiledName), indexOf.call(JS_FORBIDDEN, ref6) >= 0) {
            compiledName.unshift(this.makeCode('"'));
            compiledName.push(this.makeCode('"'));
          }
          return compiledName.concat(this.makeCode(": "), val);
        }
        answer = compiledName.concat(this.makeCode(` ${this.context || '='} `), val);
        if (o.level > LEVEL_LIST || (isValue && this.variable.base instanceof Obj && !this.param)) {
          return this.wrapInParentheses(answer);
        } else {
          return answer;
        }
      }

      compileDestructuring(o) {
        var acc, assigns, code, defaultValue, expandedIdx, fragments, i, idx, isObject, ivar, j, len1, message, name, obj, objects, olen, ref, rest, top, val, value, vvar, vvarText;
        top = o.level === LEVEL_TOP;
        ({value} = this);
        ({objects} = this.variable.base);
        olen = objects.length;
        if (olen === 0) {
          code = value.compileToFragments(o);
          if (o.level >= LEVEL_OP) {
            return this.wrapInParentheses(code);
          } else {
            return code;
          }
        }
        [obj] = objects;
        if (olen === 1 && obj instanceof Expansion) {
          obj.error('Destructuring assignment has no target');
        }
        isObject = this.variable.isObject();
        if (top && olen === 1 && !(obj instanceof Splat)) {
          defaultValue = void 0;
          if (obj instanceof Assign && obj.context === 'object') {
            ({
              variable: {
                base: idx
              },
              value: obj
            } = obj);
            if (obj instanceof Assign) {
              defaultValue = obj.value;
              obj = obj.variable;
            }
          } else {
            if (obj instanceof Assign) {
              defaultValue = obj.value;
              obj = obj.variable;
            }
            idx = isObject ? obj["this"] ? obj.properties[0].name : new PropertyName(obj.unwrap().value) : new NumberLiteral(0);
          }
          acc = idx.unwrap() instanceof PropertyName;
          value = new Value(value);
          value.properties.push(new (acc ? Access : Index)(idx));
          message = isUnassignable(obj.unwrap().value);
          if (message) {
            obj.error(message);
          }
          if (defaultValue) {
            defaultValue.isDefaultValue = true;
            value = new Op('?', value, defaultValue);
          }
          return new Assign(obj, value, null, {
            param: this.param
          }).compileToFragments(o, LEVEL_TOP);
        }
        vvar = value.compileToFragments(o, LEVEL_LIST);
        vvarText = fragmentsToText(vvar);
        assigns = [];
        expandedIdx = false;
        if (!(value.unwrap() instanceof IdentifierLiteral) || this.variable.assigns(vvarText)) {
          ref = o.scope.freeVariable('ref');
          assigns.push([this.makeCode(ref + ' = '), ...vvar]);
          vvar = [this.makeCode(ref)];
          vvarText = ref;
        }
        for (i = j = 0, len1 = objects.length; j < len1; i = ++j) {
          obj = objects[i];
          idx = i;
          if (!expandedIdx && obj instanceof Splat) {
            name = obj.name.unwrap().value;
            obj = obj.unwrap();
            val = `${olen} <= ${vvarText}.length ? ${utility('slice', o)}.call(${vvarText}, ${i}`;
            rest = olen - i - 1;
            if (rest !== 0) {
              ivar = o.scope.freeVariable('i', {
                single: true
              });
              val += `, ${ivar} = ${vvarText}.length - ${rest}) : (${ivar} = ${i}, [])`;
            } else {
              val += ") : []";
            }
            val = new Literal(val);
            expandedIdx = `${ivar}++`;
          } else if (!expandedIdx && obj instanceof Expansion) {
            rest = olen - i - 1;
            if (rest !== 0) {
              if (rest === 1) {
                expandedIdx = `${vvarText}.length - 1`;
              } else {
                ivar = o.scope.freeVariable('i', {
                  single: true
                });
                val = new Literal(`${ivar} = ${vvarText}.length - ${rest}`);
                expandedIdx = `${ivar}++`;
                assigns.push(val.compileToFragments(o, LEVEL_LIST));
              }
            }
            continue;
          } else {
            if (obj instanceof Splat || obj instanceof Expansion) {
              obj.error("multiple splats/expansions are disallowed in an assignment");
            }
            defaultValue = void 0;
            if (obj instanceof Assign && obj.context === 'object') {
              ({
                variable: {
                  base: idx
                },
                value: obj
              } = obj);
              if (obj instanceof Assign) {
                defaultValue = obj.value;
                obj = obj.variable;
              }
            } else {
              if (obj instanceof Assign) {
                defaultValue = obj.value;
                obj = obj.variable;
              }
              idx = isObject ? obj["this"] ? obj.properties[0].name : new PropertyName(obj.unwrap().value) : new Literal(expandedIdx || idx);
            }
            name = obj.unwrap().value;
            acc = idx.unwrap() instanceof PropertyName;
            val = new Value(new Literal(vvarText), [new (acc ? Access : Index)(idx)]);
            if (defaultValue) {
              defaultValue.isDefaultValue = true;
              val = new Op('?', val, defaultValue);
            }
          }
          if (name != null) {
            message = isUnassignable(name);
            if (message) {
              obj.error(message);
            }
          }
          assigns.push(new Assign(obj, val, null, {
            param: this.param,
            subpattern: true
          }).compileToFragments(o, LEVEL_LIST));
        }
        if (!(top || this.subpattern)) {
          assigns.push(vvar);
        }
        fragments = this.joinFragmentArrays(assigns, ', ');
        if (o.level < LEVEL_LIST) {
          return fragments;
        } else {
          return this.wrapInParentheses(fragments);
        }
      }

      compileConditional(o) {
        var fragments, left, right;
        [left, right] = this.variable.cacheReference(o);
        if (!left.properties.length && left.base instanceof Literal && !(left.base instanceof ThisLiteral) && !o.scope.check(left.base.value)) {
          this.variable.error(`the variable \"${left.base.value}\" can't be assigned with ${this.context} because it has not been declared before`);
        }
        if (indexOf.call(this.context, "?") >= 0) {
          o.isExistentialEquals = true;
          return new If(new Existence(left), right, {
            type: 'if'
          }).addElse(new Assign(right, this.value, '=')).compileToFragments(o);
        } else {
          fragments = new Op(this.context.slice(0, -1), left, new Assign(right, this.value, '=')).compileToFragments(o);
          if (o.level <= LEVEL_LIST) {
            return fragments;
          } else {
            return this.wrapInParentheses(fragments);
          }
        }
      }

      compileSpecialMath(o) {
        var left, right;
        [left, right] = this.variable.cacheReference(o);
        return new Assign(left, new Op(this.context.slice(0, -1), right, this.value)).compileToFragments(o);
      }

      compileSplice(o) {
        var answer, exclusive, from, fromDecl, fromRef, name, to, valDef, valRef;
        ({
          range: {from, to, exclusive}
        } = this.variable.properties.pop());
        name = this.variable.compile(o);
        if (from) {
          [fromDecl, fromRef] = this.cacheToCodeFragments(from.cache(o, LEVEL_OP));
        } else {
          fromDecl = fromRef = '0';
        }
        if (to) {
          if ((from != null ? from.isNumber() : void 0) && to.isNumber()) {
            to = to.compile(o) - fromRef;
            if (!exclusive) {
              to += 1;
            }
          } else {
            to = to.compile(o, LEVEL_ACCESS) + ' - ' + fromRef;
            if (!exclusive) {
              to += ' + 1';
            }
          }
        } else {
          to = "9e9";
        }
        [valDef, valRef] = this.value.cache(o, LEVEL_LIST);
        answer = [].concat(this.makeCode(`[].splice.apply(${name}, [${fromDecl}, ${to}].concat(`), valDef, this.makeCode(")), "), valRef);
        if (o.level > LEVEL_TOP) {
          return this.wrapInParentheses(answer);
        } else {
          return answer;
        }
      }

      eachName(iterator) {
        return this.variable.unwrapAll().eachName(iterator);
      }

    };

    Assign.prototype.children = ['variable', 'value'];

    Assign.prototype.isAssignable = YES;

    return Assign;

  })();

  exports.Code = Code = (function() {
    class Code extends Base {
      constructor(params, body, tag) {
        super();
        this.params = params || [];
        this.body = body || new Block;
        this.bound = tag === 'boundfunc';
        this.isGenerator = false;
        this.isAsync = false;
        this.isMethod = false;
        this.body.traverseChildren(false, (node) => {
          if ((node instanceof Op && node.isYield()) || node instanceof YieldReturn) {
            this.isGenerator = true;
          }
          if ((node instanceof Op && node.isAwait()) || node instanceof AwaitReturn) {
            this.isAsync = true;
          }
          if (this.isGenerator && this.isAsync) {
            return node.error("function can't contain both yield and await");
          }
        });
      }

      isStatement() {
        return this.isMethod;
      }

      makeScope(parentScope) {
        return new Scope(parentScope, this.body, this);
      }

      compileNode(o) {
        var answer, body, condition, exprs, haveBodyParam, haveSplatParam, i, ifTrue, j, k, len1, len2, m, methodScope, modifiers, name, param, paramNames, params, paramsAfterSplat, ref, ref1, ref2, ref3, ref4, ref5, signature, splatParamName, thisAssignments, wasEmpty;
        if (this.ctor) {
          if (this.isAsync) {
            this.name.error('Class constructor may not be async');
          }
          if (this.isGenerator) {
            this.name.error('Class constructor may not be a generator');
          }
        }
        if (this.bound) {
          if ((ref1 = o.scope.method) != null ? ref1.bound : void 0) {
            this.context = o.scope.method.context;
          }
          if (!this.context) {
            this.context = 'this';
          }
        }
        o.scope = del(o, 'classScope') || this.makeScope(o.scope);
        o.scope.shared = del(o, 'sharedScope');
        o.indent += TAB;
        delete o.bare;
        delete o.isExistentialEquals;
        params = [];
        exprs = [];
        thisAssignments = (ref2 = (ref3 = this.thisAssignments) != null ? ref3.slice() : void 0) != null ? ref2 : [];
        paramsAfterSplat = [];
        haveSplatParam = false;
        haveBodyParam = false;
        paramNames = [];
        this.eachParamName(function(name, node, param) {
          var target;
          if (indexOf.call(paramNames, name) >= 0) {
            node.error(`multiple parameters named '${name}'`);
          }
          paramNames.push(name);
          if (node["this"]) {
            name = node.properties[0].name.value;
            if (indexOf.call(JS_FORBIDDEN, name) >= 0) {
              name = `_${name}`;
            }
            target = new IdentifierLiteral(o.scope.freeVariable(name));
            param.renameParam(node, target);
            return thisAssignments.push(new Assign(node, target));
          }
        });
        ref4 = this.params;
        for (i = j = 0, len1 = ref4.length; j < len1; i = ++j) {
          param = ref4[i];
          if (param.splat || param instanceof Expansion) {
            if (haveSplatParam) {
              param.error('only one splat or expansion parameter is allowed per function definition');
            } else if (param instanceof Expansion && this.params.length === 1) {
              param.error('an expansion parameter cannot be the only parameter in a function definition');
            }
            haveSplatParam = true;
            if (param.splat) {
              if (param.name instanceof Arr) {
                splatParamName = o.scope.freeVariable('arg');
                params.push(ref = new Value(new IdentifierLiteral(splatParamName)));
                exprs.push(new Assign(new Value(param.name), ref, null, {
                  param: true
                }));
              } else {
                params.push(ref = param.asReference(o));
                splatParamName = fragmentsToText(ref.compileNode(o));
              }
              if (param.shouldCache()) {
                exprs.push(new Assign(new Value(param.name), ref, null, {
                  param: true
                }));
              }
            } else {
              splatParamName = o.scope.freeVariable('args');
              params.push(new Value(new IdentifierLiteral(splatParamName)));
            }
            o.scope.parameter(splatParamName);
          } else {
            if (param.shouldCache() || haveBodyParam) {
              param.assignedInBody = true;
              haveBodyParam = true;
              if (param.value != null) {
                condition = new Op('===', param, new UndefinedLiteral);
                ifTrue = new Assign(new Value(param.name), param.value, null, {
                  param: true
                });
                exprs.push(new If(condition, ifTrue));
              } else {
                exprs.push(new Assign(new Value(param.name), param.asReference(o), null, {
                  param: true
                }));
              }
            }
            if (!haveSplatParam) {
              if (param.shouldCache()) {
                ref = param.asReference(o);
              } else {
                if ((param.value != null) && !param.assignedInBody) {
                  ref = new Assign(new Value(param.name), param.value, null, {
                    param: true
                  });
                } else {
                  ref = param;
                }
              }
              if (param.name instanceof Arr || param.name instanceof Obj) {
                param.name.lhs = true;
                param.name.eachName(function(prop) {
                  return o.scope.parameter(prop.value);
                });
              } else {
                o.scope.parameter(fragmentsToText((param.value != null ? param : ref).compileToFragments(o)));
              }
              params.push(ref);
            } else {
              paramsAfterSplat.push(param);
              if ((param.value != null) && !param.shouldCache()) {
                condition = new Op('===', param, new UndefinedLiteral);
                ifTrue = new Assign(new Value(param.name), param.value);
                exprs.push(new If(condition, ifTrue));
              }
              if (((ref5 = param.name) != null ? ref5.value : void 0) != null) {
                o.scope.add(param.name.value, 'var', true);
              }
            }
          }
        }
        if (paramsAfterSplat.length !== 0) {
          exprs.unshift(new Assign(new Value(new Arr([
            new Splat(new IdentifierLiteral(splatParamName)), ...(function() {
              var k, len2, results;
              results = [];
              for (k = 0, len2 = paramsAfterSplat.length; k < len2; k++) {
                param = paramsAfterSplat[k];
                results.push(param.asReference(o));
              }
              return results;
            })()
          ])), new Value(new IdentifierLiteral(splatParamName))));
        }
        wasEmpty = this.body.isEmpty();
        if (!this.expandCtorSuper(thisAssignments)) {
          this.body.expressions.unshift(...thisAssignments);
        }
        this.body.expressions.unshift(...exprs);
        if (!(wasEmpty || this.noReturn)) {
          this.body.makeReturn();
        }
        modifiers = [];
        if (this.isMethod && this.isStatic) {
          modifiers.push('static');
        }
        if (this.isAsync) {
          modifiers.push('async');
        }
        if (!(this.isMethod || this.bound)) {
          modifiers.push(`function${(this.isGenerator ? '*' : '')}`);
        } else if (this.isGenerator) {
          modifiers.push('*');
        }
        signature = [this.makeCode('(')];
        for (i = k = 0, len2 = params.length; k < len2; i = ++k) {
          param = params[i];
          if (i) {
            signature.push(this.makeCode(', '));
          }
          if (haveSplatParam && i === params.length - 1) {
            signature.push(this.makeCode('...'));
          }
          signature.push(...param.compileToFragments(o));
        }
        signature.push(this.makeCode(')'));
        if (!this.body.isEmpty()) {
          body = this.body.compileWithDeclarations(o);
        }
        if (this.isMethod) {
          [methodScope, o.scope] = [o.scope, o.scope.parent];
          name = this.name.compileToFragments(o);
          if (name[0].code === '.') {
            name.shift();
          }
          o.scope = methodScope;
        }
        answer = this.joinFragmentArrays((function() {
          var l, len3, results;
          results = [];
          for (l = 0, len3 = modifiers.length; l < len3; l++) {
            m = modifiers[l];
            results.push(this.makeCode(m));
          }
          return results;
        }).call(this), ' ');
        if (modifiers.length && name) {
          answer.push(this.makeCode(' '));
        }
        if (name) {
          answer.push(...name);
        }
        answer.push(...signature);
        if (this.bound && !this.isMethod) {
          answer.push(this.makeCode(' =>'));
        }
        answer.push(this.makeCode(' {'));
        if (body != null ? body.length : void 0) {
          answer.push(this.makeCode('\n'), ...body, this.makeCode(`\n${this.tab}`));
        }
        answer.push(this.makeCode('}'));
        if (this.isMethod) {
          return [this.makeCode(this.tab), ...answer];
        }
        if (this.front || (o.level >= LEVEL_ACCESS)) {
          return this.wrapInParentheses(answer);
        } else {
          return answer;
        }
      }

      eachParamName(iterator) {
        var j, len1, param, ref1, results;
        ref1 = this.params;
        results = [];
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          param = ref1[j];
          results.push(param.eachName(iterator));
        }
        return results;
      }

      traverseChildren(crossScope, func) {
        if (crossScope) {
          return super.traverseChildren(crossScope, func);
        }
      }

      replaceInContext(child, replacement) {
        if (this.bound) {
          return super.replaceInContext(child, replacement);
        } else {
          return false;
        }
      }

      expandCtorSuper(thisAssignments) {
        var haveThisParam, param, ref1, seenSuper;
        if (!this.ctor) {
          return false;
        }
        this.eachSuperCall(Block.wrap(this.params), function(superCall) {
          return superCall.error("'super' is not allowed in constructor parameter defaults");
        });
        seenSuper = this.eachSuperCall(this.body, (superCall) => {
          if (this.ctor === 'base') {
            superCall.error("'super' is only allowed in derived class constructors");
          }
          return superCall.expressions = thisAssignments;
        });
        haveThisParam = thisAssignments.length && thisAssignments.length !== ((ref1 = this.thisAssignments) != null ? ref1.length : void 0);
        if (this.ctor === 'derived' && !seenSuper && haveThisParam) {
          param = thisAssignments[0].variable;
          param.error("Can't use @params in derived class constructors without calling super");
        }
        return seenSuper;
      }

      eachSuperCall(context, iterator) {
        var seenSuper;
        seenSuper = false;
        context.traverseChildren(true, (child) => {
          if (child instanceof SuperCall) {
            seenSuper = true;
            iterator(child);
          } else if (child instanceof ThisLiteral && this.ctor === 'derived' && !seenSuper) {
            child.error("Can't reference 'this' before calling super in derived class constructors");
          }
          return !(child instanceof SuperCall) && (!(child instanceof Code) || child.bound);
        });
        return seenSuper;
      }

    };

    Code.prototype.children = ['params', 'body'];

    Code.prototype.jumps = NO;

    return Code;

  })();

  exports.Param = Param = (function() {
    class Param extends Base {
      constructor(name1, value1, splat) {
        var message, token;
        super();
        this.name = name1;
        this.value = value1;
        this.splat = splat;
        message = isUnassignable(this.name.unwrapAll().value);
        if (message) {
          this.name.error(message);
        }
        if (this.name instanceof Obj && this.name.generated) {
          token = this.name.objects[0].operatorToken;
          token.error(`unexpected ${token.value}`);
        }
      }

      compileToFragments(o) {
        return this.name.compileToFragments(o, LEVEL_LIST);
      }

      asReference(o) {
        var name, node;
        if (this.reference) {
          return this.reference;
        }
        node = this.name;
        if (node["this"]) {
          name = node.properties[0].name.value;
          if (indexOf.call(JS_FORBIDDEN, name) >= 0) {
            name = `_${name}`;
          }
          node = new IdentifierLiteral(o.scope.freeVariable(name));
        } else if (node.shouldCache()) {
          node = new IdentifierLiteral(o.scope.freeVariable('arg'));
        }
        node = new Value(node);
        node.updateLocationDataIfMissing(this.locationData);
        return this.reference = node;
      }

      shouldCache() {
        return this.name.shouldCache();
      }

      eachName(iterator, name = this.name) {
        var atParam, j, len1, node, obj, ref1, ref2;
        atParam = (obj) => {
          return iterator(`@${obj.properties[0].name.value}`, obj, this);
        };
        if (name instanceof Literal) {
          return iterator(name.value, name, this);
        }
        if (name instanceof Value) {
          return atParam(name);
        }
        ref2 = (ref1 = name.objects) != null ? ref1 : [];
        for (j = 0, len1 = ref2.length; j < len1; j++) {
          obj = ref2[j];
          if (obj instanceof Assign && (obj.context == null)) {
            obj = obj.variable;
          }
          if (obj instanceof Assign) {
            if (obj.value instanceof Assign) {
              obj = obj.value;
            }
            this.eachName(iterator, obj.value.unwrap());
          } else if (obj instanceof Splat) {
            node = obj.name.unwrap();
            iterator(node.value, node, this);
          } else if (obj instanceof Value) {
            if (obj.isArray() || obj.isObject()) {
              this.eachName(iterator, obj.base);
            } else if (obj["this"]) {
              atParam(obj);
            } else {
              iterator(obj.base.value, obj.base, this);
            }
          } else if (!(obj instanceof Expansion)) {
            obj.error(`illegal parameter ${obj.compile()}`);
          }
        }
      }

      renameParam(node, newNode) {
        var isNode, replacement;
        isNode = function(candidate) {
          return candidate === node;
        };
        replacement = (node, parent) => {
          var key;
          if (parent instanceof Obj) {
            key = node;
            if (node["this"]) {
              key = node.properties[0].name;
            }
            return new Assign(new Value(key), newNode, 'object');
          } else {
            return newNode;
          }
        };
        return this.replaceInContext(isNode, replacement);
      }

    };

    Param.prototype.children = ['name', 'value'];

    return Param;

  })();

  exports.Splat = Splat = (function() {
    class Splat extends Base {
      isAssignable() {
        return this.name.isAssignable() && (!this.name.isAtomic || this.name.isAtomic());
      }

      constructor(name) {
        super();
        this.name = name.compile ? name : new Literal(name);
      }

      assigns(name) {
        return this.name.assigns(name);
      }

      compileToFragments(o) {
        return [this.makeCode('...'), ...this.name.compileToFragments(o)];
      }

      unwrap() {
        return this.name;
      }

    };

    Splat.prototype.children = ['name'];

    return Splat;

  })();

  exports.Expansion = Expansion = (function() {
    class Expansion extends Base {
      compileNode(o) {
        return this.error('Expansion must be used inside a destructuring assignment or parameter list');
      }

      asReference(o) {
        return this;
      }

      eachName(iterator) {}

    };

    Expansion.prototype.shouldCache = NO;

    return Expansion;

  })();

  exports.While = While = (function() {
    class While extends Base {
      constructor(condition, options) {
        super();
        this.condition = (options != null ? options.invert : void 0) ? condition.invert() : condition;
        this.guard = options != null ? options.guard : void 0;
      }

      makeReturn(res) {
        if (res) {
          return super.makeReturn(res);
        } else {
          this.returns = !this.jumps({
            loop: true
          });
          return this;
        }
      }

      addBody(body1) {
        this.body = body1;
        return this;
      }

      jumps() {
        var expressions, j, jumpNode, len1, node;
        ({expressions} = this.body);
        if (!expressions.length) {
          return false;
        }
        for (j = 0, len1 = expressions.length; j < len1; j++) {
          node = expressions[j];
          if (jumpNode = node.jumps({
            loop: true
          })) {
            return jumpNode;
          }
        }
        return false;
      }

      compileNode(o) {
        var answer, body, rvar, set;
        o.indent += TAB;
        set = '';
        ({body} = this);
        if (body.isEmpty()) {
          body = this.makeCode('');
        } else {
          if (this.returns) {
            body.makeReturn(rvar = o.scope.freeVariable('results'));
            set = `${this.tab}${rvar} = [];\n`;
          }
          if (this.guard) {
            if (body.expressions.length > 1) {
              body.expressions.unshift(new If((new Parens(this.guard)).invert(), new StatementLiteral("continue")));
            } else {
              if (this.guard) {
                body = Block.wrap([new If(this.guard, body)]);
              }
            }
          }
          body = [].concat(this.makeCode("\n"), body.compileToFragments(o, LEVEL_TOP), this.makeCode(`\n${this.tab}`));
        }
        answer = [].concat(this.makeCode(set + this.tab + "while ("), this.condition.compileToFragments(o, LEVEL_PAREN), this.makeCode(") {"), body, this.makeCode("}"));
        if (this.returns) {
          answer.push(this.makeCode(`\n${this.tab}return ${rvar};`));
        }
        return answer;
      }

    };

    While.prototype.children = ['condition', 'guard', 'body'];

    While.prototype.isStatement = YES;

    return While;

  })();

  exports.Op = Op = (function() {
    var CONVERSIONS, INVERSIONS;

    class Op extends Base {
      constructor(op, first, second, flip) {
        if (op === 'in') {
          return new In(first, second);
        }
        if (op === 'do') {
          return Op.prototype.generateDo(first);
        }
        if (op === 'new') {
          if (first instanceof Call && !first["do"] && !first.isNew) {
            return first.newInstance();
          }
          if (first instanceof Code && first.bound || first["do"]) {
            first = new Parens(first);
          }
        }
        super();
        this.operator = CONVERSIONS[op] || op;
        this.first = first;
        this.second = second;
        this.flip = !!flip;
        return this;
      }

      isNumber() {
        var ref1;
        return this.isUnary() && ((ref1 = this.operator) === '+' || ref1 === '-') && this.first instanceof Value && this.first.isNumber();
      }

      isAwait() {
        return this.operator === 'await';
      }

      isYield() {
        var ref1;
        return (ref1 = this.operator) === 'yield' || ref1 === 'yield*';
      }

      isUnary() {
        return !this.second;
      }

      shouldCache() {
        return !this.isNumber();
      }

      isChainable() {
        var ref1;
        return (ref1 = this.operator) === '<' || ref1 === '>' || ref1 === '>=' || ref1 === '<=' || ref1 === '===' || ref1 === '!==';
      }

      invert() {
        var allInvertable, curr, fst, op, ref1;
        if (this.isChainable() && this.first.isChainable()) {
          allInvertable = true;
          curr = this;
          while (curr && curr.operator) {
            allInvertable && (allInvertable = curr.operator in INVERSIONS);
            curr = curr.first;
          }
          if (!allInvertable) {
            return new Parens(this).invert();
          }
          curr = this;
          while (curr && curr.operator) {
            curr.invert = !curr.invert;
            curr.operator = INVERSIONS[curr.operator];
            curr = curr.first;
          }
          return this;
        } else if (op = INVERSIONS[this.operator]) {
          this.operator = op;
          if (this.first.unwrap() instanceof Op) {
            this.first.invert();
          }
          return this;
        } else if (this.second) {
          return new Parens(this).invert();
        } else if (this.operator === '!' && (fst = this.first.unwrap()) instanceof Op && ((ref1 = fst.operator) === '!' || ref1 === 'in' || ref1 === 'instanceof')) {
          return fst;
        } else {
          return new Op('!', this);
        }
      }

      unfoldSoak(o) {
        var ref1;
        return ((ref1 = this.operator) === '++' || ref1 === '--' || ref1 === 'delete') && unfoldSoak(o, this, 'first');
      }

      generateDo(exp) {
        var call, func, j, len1, param, passedParams, ref, ref1;
        passedParams = [];
        func = exp instanceof Assign && (ref = exp.value.unwrap()) instanceof Code ? ref : exp;
        ref1 = func.params || [];
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          param = ref1[j];
          if (param.value) {
            passedParams.push(param.value);
            delete param.value;
          } else {
            passedParams.push(param);
          }
        }
        call = new Call(exp, passedParams);
        call["do"] = true;
        return call;
      }

      compileNode(o) {
        var answer, isChain, lhs, message, ref1, rhs;
        isChain = this.isChainable() && this.first.isChainable();
        if (!isChain) {
          this.first.front = this.front;
        }
        if (this.operator === 'delete' && o.scope.check(this.first.unwrapAll().value)) {
          this.error('delete operand may not be argument or var');
        }
        if ((ref1 = this.operator) === '--' || ref1 === '++') {
          message = isUnassignable(this.first.unwrapAll().value);
          if (message) {
            this.first.error(message);
          }
        }
        if (this.isYield() || this.isAwait()) {
          return this.compileContinuation(o);
        }
        if (this.isUnary()) {
          return this.compileUnary(o);
        }
        if (isChain) {
          return this.compileChain(o);
        }
        switch (this.operator) {
          case '?':
            return this.compileExistence(o, this.second.isDefaultValue);
          case '**':
            return this.compilePower(o);
          case '//':
            return this.compileFloorDivision(o);
          case '%%':
            return this.compileModulo(o);
          default:
            lhs = this.first.compileToFragments(o, LEVEL_OP);
            rhs = this.second.compileToFragments(o, LEVEL_OP);
            answer = [].concat(lhs, this.makeCode(` ${this.operator} `), rhs);
            if (o.level <= LEVEL_OP) {
              return answer;
            } else {
              return this.wrapInParentheses(answer);
            }
        }
      }

      compileChain(o) {
        var fragments, fst, shared;
        [this.first.second, shared] = this.first.second.cache(o);
        fst = this.first.compileToFragments(o, LEVEL_OP);
        fragments = fst.concat(this.makeCode(` ${(this.invert ? '&&' : '||')} `), shared.compileToFragments(o), this.makeCode(` ${this.operator} `), this.second.compileToFragments(o, LEVEL_OP));
        return this.wrapInParentheses(fragments);
      }

      compileExistence(o, checkOnlyUndefined) {
        var fst, ref;
        if (this.first.shouldCache()) {
          ref = new IdentifierLiteral(o.scope.freeVariable('ref'));
          fst = new Parens(new Assign(ref, this.first));
        } else {
          fst = this.first;
          ref = fst;
        }
        return new If(new Existence(fst, checkOnlyUndefined), ref, {
          type: 'if'
        }).addElse(this.second).compileToFragments(o);
      }

      compileUnary(o) {
        var op, parts, plusMinus;
        parts = [];
        op = this.operator;
        parts.push([this.makeCode(op)]);
        if (op === '!' && this.first instanceof Existence) {
          this.first.negated = !this.first.negated;
          return this.first.compileToFragments(o);
        }
        if (o.level >= LEVEL_ACCESS) {
          return (new Parens(this)).compileToFragments(o);
        }
        plusMinus = op === '+' || op === '-';
        if ((op === 'new' || op === 'typeof' || op === 'delete') || plusMinus && this.first instanceof Op && this.first.operator === op) {
          parts.push([this.makeCode(' ')]);
        }
        if ((plusMinus && this.first instanceof Op) || (op === 'new' && this.first.isStatement(o))) {
          this.first = new Parens(this.first);
        }
        parts.push(this.first.compileToFragments(o, LEVEL_OP));
        if (this.flip) {
          parts.reverse();
        }
        return this.joinFragmentArrays(parts, '');
      }

      compileContinuation(o) {
        var op, parts, ref1, ref2;
        parts = [];
        op = this.operator;
        if (o.scope.parent == null) {
          this.error(`${this.operator} can only occur inside functions`);
        }
        if (((ref1 = o.scope.method) != null ? ref1.bound : void 0) && o.scope.method.isGenerator) {
          this.error('yield cannot occur inside bound (fat arrow) functions');
        }
        if (indexOf.call(Object.keys(this.first), 'expression') >= 0 && !(this.first instanceof Throw)) {
          if (this.first.expression != null) {
            parts.push(this.first.expression.compileToFragments(o, LEVEL_OP));
          }
        } else {
          if (o.level >= LEVEL_PAREN) {
            parts.push([this.makeCode("(")]);
          }
          parts.push([this.makeCode(op)]);
          if (((ref2 = this.first.base) != null ? ref2.value : void 0) !== '') {
            parts.push([this.makeCode(" ")]);
          }
          parts.push(this.first.compileToFragments(o, LEVEL_OP));
          if (o.level >= LEVEL_PAREN) {
            parts.push([this.makeCode(")")]);
          }
        }
        return this.joinFragmentArrays(parts, '');
      }

      compilePower(o) {
        var pow;
        pow = new Value(new IdentifierLiteral('Math'), [new Access(new PropertyName('pow'))]);
        return new Call(pow, [this.first, this.second]).compileToFragments(o);
      }

      compileFloorDivision(o) {
        var div, floor, second;
        floor = new Value(new IdentifierLiteral('Math'), [new Access(new PropertyName('floor'))]);
        second = this.second.shouldCache() ? new Parens(this.second) : this.second;
        div = new Op('/', this.first, second);
        return new Call(floor, [div]).compileToFragments(o);
      }

      compileModulo(o) {
        var mod;
        mod = new Value(new Literal(utility('modulo', o)));
        return new Call(mod, [this.first, this.second]).compileToFragments(o);
      }

      toString(idt) {
        return super.toString(idt, this.constructor.name + ' ' + this.operator);
      }

    };

    CONVERSIONS = {
      '==': '===',
      '!=': '!==',
      'of': 'in',
      'yieldfrom': 'yield*'
    };

    INVERSIONS = {
      '!==': '===',
      '===': '!=='
    };

    Op.prototype.children = ['first', 'second'];

    return Op;

  })();

  exports.In = In = (function() {
    class In extends Base {
      constructor(object, array) {
        super();
        this.object = object;
        this.array = array;
      }

      compileNode(o) {
        var hasSplat, j, len1, obj, ref1;
        if (this.array instanceof Value && this.array.isArray() && this.array.base.objects.length) {
          ref1 = this.array.base.objects;
          for (j = 0, len1 = ref1.length; j < len1; j++) {
            obj = ref1[j];
            if (!(obj instanceof Splat)) {
              continue;
            }
            hasSplat = true;
            break;
          }
          if (!hasSplat) {
            return this.compileOrTest(o);
          }
        }
        return this.compileLoopTest(o);
      }

      compileOrTest(o) {
        var cmp, cnj, i, item, j, len1, ref, ref1, sub, tests;
        [sub, ref] = this.object.cache(o, LEVEL_OP);
        [cmp, cnj] = this.negated ? [' !== ', ' && '] : [' === ', ' || '];
        tests = [];
        ref1 = this.array.base.objects;
        for (i = j = 0, len1 = ref1.length; j < len1; i = ++j) {
          item = ref1[i];
          if (i) {
            tests.push(this.makeCode(cnj));
          }
          tests = tests.concat((i ? ref : sub), this.makeCode(cmp), item.compileToFragments(o, LEVEL_ACCESS));
        }
        if (o.level < LEVEL_OP) {
          return tests;
        } else {
          return this.wrapInParentheses(tests);
        }
      }

      compileLoopTest(o) {
        var fragments, ref, sub;
        [sub, ref] = this.object.cache(o, LEVEL_LIST);
        fragments = [].concat(this.makeCode(utility('indexOf', o) + ".call("), this.array.compileToFragments(o, LEVEL_LIST), this.makeCode(", "), ref, this.makeCode(") " + (this.negated ? '< 0' : '>= 0')));
        if (fragmentsToText(sub) === fragmentsToText(ref)) {
          return fragments;
        }
        fragments = sub.concat(this.makeCode(', '), fragments);
        if (o.level < LEVEL_LIST) {
          return fragments;
        } else {
          return this.wrapInParentheses(fragments);
        }
      }

      toString(idt) {
        return super.toString(idt, this.constructor.name + (this.negated ? '!' : ''));
      }

    };

    In.prototype.children = ['object', 'array'];

    In.prototype.invert = NEGATE;

    return In;

  })();

  exports.Try = Try = (function() {
    class Try extends Base {
      constructor(attempt, errorVariable, recovery, ensure) {
        super();
        this.attempt = attempt;
        this.errorVariable = errorVariable;
        this.recovery = recovery;
        this.ensure = ensure;
      }

      jumps(o) {
        var ref1;
        return this.attempt.jumps(o) || ((ref1 = this.recovery) != null ? ref1.jumps(o) : void 0);
      }

      makeReturn(res) {
        if (this.attempt) {
          this.attempt = this.attempt.makeReturn(res);
        }
        if (this.recovery) {
          this.recovery = this.recovery.makeReturn(res);
        }
        return this;
      }

      compileNode(o) {
        var catchPart, ensurePart, generatedErrorVariableName, message, placeholder, tryPart;
        o.indent += TAB;
        tryPart = this.attempt.compileToFragments(o, LEVEL_TOP);
        catchPart = this.recovery ? (generatedErrorVariableName = o.scope.freeVariable('error', {
          reserve: false
        }), placeholder = new IdentifierLiteral(generatedErrorVariableName), this.errorVariable ? (message = isUnassignable(this.errorVariable.unwrapAll().value), message ? this.errorVariable.error(message) : void 0, this.recovery.unshift(new Assign(this.errorVariable, placeholder))) : void 0, [].concat(this.makeCode(" catch ("), placeholder.compileToFragments(o), this.makeCode(") {\n"), this.recovery.compileToFragments(o, LEVEL_TOP), this.makeCode(`\n${this.tab}}`))) : !(this.ensure || this.recovery) ? (generatedErrorVariableName = o.scope.freeVariable('error', {
          reserve: false
        }), [this.makeCode(` catch (${generatedErrorVariableName}) {}`)]) : [];
        ensurePart = this.ensure ? [].concat(this.makeCode(" finally {\n"), this.ensure.compileToFragments(o, LEVEL_TOP), this.makeCode(`\n${this.tab}}`)) : [];
        return [].concat(this.makeCode(`${this.tab}try {\n`), tryPart, this.makeCode(`\n${this.tab}}`), catchPart, ensurePart);
      }

    };

    Try.prototype.children = ['attempt', 'recovery', 'ensure'];

    Try.prototype.isStatement = YES;

    return Try;

  })();

  exports.Throw = Throw = (function() {
    class Throw extends Base {
      constructor(expression1) {
        super();
        this.expression = expression1;
      }

      compileNode(o) {
        return [].concat(this.makeCode(this.tab + "throw "), this.expression.compileToFragments(o), this.makeCode(";"));
      }

    };

    Throw.prototype.children = ['expression'];

    Throw.prototype.isStatement = YES;

    Throw.prototype.jumps = NO;

    Throw.prototype.makeReturn = THIS;

    return Throw;

  })();

  exports.Existence = Existence = (function() {
    class Existence extends Base {
      constructor(expression1, onlyNotUndefined = false) {
        super();
        this.expression = expression1;
        this.comparisonTarget = onlyNotUndefined ? 'undefined' : 'null';
      }

      compileNode(o) {
        var cmp, cnj, code;
        this.expression.front = this.front;
        code = this.expression.compile(o, LEVEL_OP);
        if (this.expression.unwrap() instanceof IdentifierLiteral && !o.scope.check(code)) {
          [cmp, cnj] = this.negated ? ['===', '||'] : ['!==', '&&'];
          code = `typeof ${code} ${cmp} \"undefined\"` + (this.comparisonTarget !== 'undefined' ? ` ${cnj} ${code} ${cmp} ${this.comparisonTarget}` : '');
        } else {
          cmp = this.comparisonTarget === 'null' ? this.negated ? '==' : '!=' : this.negated ? '===' : '!==';
          code = `${code} ${cmp} ${this.comparisonTarget}`;
        }
        return [this.makeCode(o.level <= LEVEL_COND ? code : `(${code})`)];
      }

    };

    Existence.prototype.children = ['expression'];

    Existence.prototype.invert = NEGATE;

    return Existence;

  })();

  exports.Parens = Parens = (function() {
    class Parens extends Base {
      constructor(body1) {
        super();
        this.body = body1;
      }

      unwrap() {
        return this.body;
      }

      shouldCache() {
        return this.body.shouldCache();
      }

      compileNode(o) {
        var bare, expr, fragments;
        expr = this.body.unwrap();
        if (expr instanceof Value && expr.isAtomic()) {
          expr.front = this.front;
          return expr.compileToFragments(o);
        }
        fragments = expr.compileToFragments(o, LEVEL_PAREN);
        bare = o.level < LEVEL_OP && (expr instanceof Op || expr instanceof Call || (expr instanceof For && expr.returns));
        if (bare) {
          return fragments;
        } else {
          return this.wrapInParentheses(fragments);
        }
      }

    };

    Parens.prototype.children = ['body'];

    return Parens;

  })();

  exports.StringWithInterpolations = StringWithInterpolations = (function() {
    class StringWithInterpolations extends Base {
      constructor(body1) {
        super();
        this.body = body1;
      }

      unwrap() {
        return this;
      }

      shouldCache() {
        return this.body.shouldCache();
      }

      compileNode(o) {
        var element, elements, expr, fragments, j, len1, value;
        expr = this.body.unwrap();
        elements = [];
        expr.traverseChildren(false, function(node) {
          if (node instanceof StringLiteral) {
            elements.push(node);
            return true;
          } else if (node instanceof Parens) {
            elements.push(node);
            return false;
          }
          return true;
        });
        fragments = [];
        fragments.push(this.makeCode('`'));
        for (j = 0, len1 = elements.length; j < len1; j++) {
          element = elements[j];
          if (element instanceof StringLiteral) {
            value = element.value.slice(1, -1);
            value = value.replace(/(\\*)(`|\$\{)/g, function(match, backslashes, toBeEscaped) {
              if (backslashes.length % 2 === 0) {
                return `${backslashes}\\${toBeEscaped}`;
              } else {
                return match;
              }
            });
            fragments.push(this.makeCode(value));
          } else {
            fragments.push(this.makeCode('${'));
            fragments.push(...element.compileToFragments(o, LEVEL_PAREN));
            fragments.push(this.makeCode('}'));
          }
        }
        fragments.push(this.makeCode('`'));
        return fragments;
      }

    };

    StringWithInterpolations.prototype.children = ['body'];

    return StringWithInterpolations;

  })();

  exports.For = For = (function() {
    class For extends While {
      constructor(body, source) {
        var ref1, ref2;
        super();
        ({source: this.source, guard: this.guard, step: this.step, name: this.name, index: this.index} = source);
        this.body = Block.wrap([body]);
        this.own = !!source.own;
        this.object = !!source.object;
        this.from = !!source.from;
        if (this.from && this.index) {
          this.index.error('cannot use index with for-from');
        }
        if (this.own && !this.object) {
          source.ownTag.error(`cannot use own with for-${(this.from ? 'from' : 'in')}`);
        }
        if (this.object) {
          [this.name, this.index] = [this.index, this.name];
        }
        if (((ref1 = this.index) != null ? typeof ref1.isArray === "function" ? ref1.isArray() : void 0 : void 0) || ((ref2 = this.index) != null ? typeof ref2.isObject === "function" ? ref2.isObject() : void 0 : void 0)) {
          this.index.error('index cannot be a pattern matching expression');
        }
        this.range = this.source instanceof Value && this.source.base instanceof Range && !this.source.properties.length && !this.from;
        this.pattern = this.name instanceof Value;
        if (this.range && this.index) {
          this.index.error('indexes do not apply to range loops');
        }
        if (this.range && this.pattern) {
          this.name.error('cannot pattern match over range loops');
        }
        this.returns = false;
      }

      compileNode(o) {
        var body, bodyFragments, compare, compareDown, declare, declareDown, defPart, defPartFragments, down, forPartFragments, guardPart, idt1, increment, index, ivar, kvar, kvarAssign, last, lvar, name, namePart, ref, ref1, resultPart, returnResult, rvar, scope, source, step, stepNum, stepVar, svar, varPart;
        body = Block.wrap([this.body]);
        ref1 = body.expressions, last = ref1[ref1.length - 1];
        if ((last != null ? last.jumps() : void 0) instanceof Return) {
          this.returns = false;
        }
        source = this.range ? this.source.base : this.source;
        scope = o.scope;
        if (!this.pattern) {
          name = this.name && (this.name.compile(o, LEVEL_LIST));
        }
        index = this.index && (this.index.compile(o, LEVEL_LIST));
        if (name && !this.pattern) {
          scope.find(name);
        }
        if (index && !(this.index instanceof Value)) {
          scope.find(index);
        }
        if (this.returns) {
          rvar = scope.freeVariable('results');
        }
        if (this.from) {
          if (this.pattern) {
            ivar = scope.freeVariable('x', {
              single: true
            });
          }
        } else {
          ivar = (this.object && index) || scope.freeVariable('i', {
            single: true
          });
        }
        kvar = ((this.range || this.from) && name) || index || ivar;
        kvarAssign = kvar !== ivar ? `${kvar} = ` : "";
        if (this.step && !this.range) {
          [step, stepVar] = this.cacheToCodeFragments(this.step.cache(o, LEVEL_LIST, shouldCacheOrIsAssignable));
          if (this.step.isNumber()) {
            stepNum = Number(stepVar);
          }
        }
        if (this.pattern) {
          name = ivar;
        }
        varPart = '';
        guardPart = '';
        defPart = '';
        idt1 = this.tab + TAB;
        if (this.range) {
          forPartFragments = source.compileToFragments(merge(o, {
            index: ivar,
            name,
            step: this.step,
            shouldCache: shouldCacheOrIsAssignable
          }));
        } else {
          svar = this.source.compile(o, LEVEL_LIST);
          if ((name || this.own) && !(this.source.unwrap() instanceof IdentifierLiteral)) {
            defPart += `${this.tab}${(ref = scope.freeVariable('ref'))} = ${svar};\n`;
            svar = ref;
          }
          if (name && !this.pattern && !this.from) {
            namePart = `${name} = ${svar}[${kvar}]`;
          }
          if (!this.object && !this.from) {
            if (step !== stepVar) {
              defPart += `${this.tab}${step};\n`;
            }
            down = stepNum < 0;
            if (!(this.step && (stepNum != null) && down)) {
              lvar = scope.freeVariable('len');
            }
            declare = `${kvarAssign}${ivar} = 0, ${lvar} = ${svar}.length`;
            declareDown = `${kvarAssign}${ivar} = ${svar}.length - 1`;
            compare = `${ivar} < ${lvar}`;
            compareDown = `${ivar} >= 0`;
            if (this.step) {
              if (stepNum != null) {
                if (down) {
                  compare = compareDown;
                  declare = declareDown;
                }
              } else {
                compare = `${stepVar} > 0 ? ${compare} : ${compareDown}`;
                declare = `(${stepVar} > 0 ? (${declare}) : ${declareDown})`;
              }
              increment = `${ivar} += ${stepVar}`;
            } else {
              increment = `${(kvar !== ivar ? `++${ivar}` : `${ivar}++`)}`;
            }
            forPartFragments = [this.makeCode(`${declare}; ${compare}; ${kvarAssign}${increment}`)];
          }
        }
        if (this.returns) {
          resultPart = `${this.tab}${rvar} = [];\n`;
          returnResult = `\n${this.tab}return ${rvar};`;
          body.makeReturn(rvar);
        }
        if (this.guard) {
          if (body.expressions.length > 1) {
            body.expressions.unshift(new If((new Parens(this.guard)).invert(), new StatementLiteral("continue")));
          } else {
            if (this.guard) {
              body = Block.wrap([new If(this.guard, body)]);
            }
          }
        }
        if (this.pattern) {
          body.expressions.unshift(new Assign(this.name, this.from ? new IdentifierLiteral(kvar) : new Literal(`${svar}[${kvar}]`)));
        }
        defPartFragments = [].concat(this.makeCode(defPart), this.pluckDirectCall(o, body));
        if (namePart) {
          varPart = `\n${idt1}${namePart};`;
        }
        if (this.object) {
          forPartFragments = [this.makeCode(`${kvar} in ${svar}`)];
          if (this.own) {
            guardPart = `\n${idt1}if (!${utility('hasProp', o)}.call(${svar}, ${kvar})) continue;`;
          }
        } else if (this.from) {
          forPartFragments = [this.makeCode(`${kvar} of ${svar}`)];
        }
        bodyFragments = body.compileToFragments(merge(o, {
          indent: idt1
        }), LEVEL_TOP);
        if (bodyFragments && bodyFragments.length > 0) {
          bodyFragments = [].concat(this.makeCode("\n"), bodyFragments, this.makeCode("\n"));
        }
        return [].concat(defPartFragments, this.makeCode(`${resultPart || ''}${this.tab}for (`), forPartFragments, this.makeCode(`) {${guardPart}${varPart}`), bodyFragments, this.makeCode(`${this.tab}}${returnResult || ''}`));
      }

      pluckDirectCall(o, body) {
        var base, defs, expr, fn, idx, j, len1, ref, ref1, ref2, ref3, ref4, ref5, ref6, val;
        defs = [];
        ref1 = body.expressions;
        for (idx = j = 0, len1 = ref1.length; j < len1; idx = ++j) {
          expr = ref1[idx];
          expr = expr.unwrapAll();
          if (!(expr instanceof Call)) {
            continue;
          }
          val = (ref2 = expr.variable) != null ? ref2.unwrapAll() : void 0;
          if (!((val instanceof Code) || (val instanceof Value && ((ref3 = val.base) != null ? ref3.unwrapAll() : void 0) instanceof Code && val.properties.length === 1 && ((ref4 = (ref5 = val.properties[0].name) != null ? ref5.value : void 0) === 'call' || ref4 === 'apply')))) {
            continue;
          }
          fn = ((ref6 = val.base) != null ? ref6.unwrapAll() : void 0) || val;
          ref = new IdentifierLiteral(o.scope.freeVariable('fn'));
          base = new Value(ref);
          if (val.base) {
            [val.base, base] = [base, val];
          }
          body.expressions[idx] = new Call(base, expr.args);
          defs = defs.concat(this.makeCode(this.tab), new Assign(ref, fn).compileToFragments(o, LEVEL_TOP), this.makeCode(';\n'));
        }
        return defs;
      }

    };

    For.prototype.children = ['body', 'source', 'guard', 'step'];

    return For;

  })();

  exports.Switch = Switch = (function() {
    class Switch extends Base {
      constructor(subject, cases, otherwise) {
        super();
        this.subject = subject;
        this.cases = cases;
        this.otherwise = otherwise;
      }

      jumps(o = {
          block: true
        }) {
        var block, conds, j, jumpNode, len1, ref1, ref2;
        ref1 = this.cases;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          [conds, block] = ref1[j];
          if (jumpNode = block.jumps(o)) {
            return jumpNode;
          }
        }
        return (ref2 = this.otherwise) != null ? ref2.jumps(o) : void 0;
      }

      makeReturn(res) {
        var j, len1, pair, ref1, ref2;
        ref1 = this.cases;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          pair = ref1[j];
          pair[1].makeReturn(res);
        }
        if (res) {
          this.otherwise || (this.otherwise = new Block([new Literal('void 0')]));
        }
        if ((ref2 = this.otherwise) != null) {
          ref2.makeReturn(res);
        }
        return this;
      }

      compileNode(o) {
        var block, body, cond, conditions, expr, fragments, i, idt1, idt2, j, k, len1, len2, ref1, ref2;
        idt1 = o.indent + TAB;
        idt2 = o.indent = idt1 + TAB;
        fragments = [].concat(this.makeCode(this.tab + "switch ("), (this.subject ? this.subject.compileToFragments(o, LEVEL_PAREN) : this.makeCode("false")), this.makeCode(") {\n"));
        ref1 = this.cases;
        for (i = j = 0, len1 = ref1.length; j < len1; i = ++j) {
          [conditions, block] = ref1[i];
          ref2 = flatten([conditions]);
          for (k = 0, len2 = ref2.length; k < len2; k++) {
            cond = ref2[k];
            if (!this.subject) {
              cond = cond.invert();
            }
            fragments = fragments.concat(this.makeCode(idt1 + "case "), cond.compileToFragments(o, LEVEL_PAREN), this.makeCode(":\n"));
          }
          if ((body = block.compileToFragments(o, LEVEL_TOP)).length > 0) {
            fragments = fragments.concat(body, this.makeCode('\n'));
          }
          if (i === this.cases.length - 1 && !this.otherwise) {
            break;
          }
          expr = this.lastNonComment(block.expressions);
          if (expr instanceof Return || (expr instanceof Literal && expr.jumps() && expr.value !== 'debugger')) {
            continue;
          }
          fragments.push(cond.makeCode(idt2 + 'break;\n'));
        }
        if (this.otherwise && this.otherwise.expressions.length) {
          fragments.push(this.makeCode(idt1 + "default:\n"), ...this.otherwise.compileToFragments(o, LEVEL_TOP), this.makeCode("\n"));
        }
        fragments.push(this.makeCode(this.tab + '}'));
        return fragments;
      }

    };

    Switch.prototype.children = ['subject', 'cases', 'otherwise'];

    Switch.prototype.isStatement = YES;

    return Switch;

  })();

  exports.If = If = (function() {
    class If extends Base {
      constructor(condition, body1, options = {}) {
        super();
        this.body = body1;
        this.condition = options.type === 'unless' ? condition.invert() : condition;
        this.elseBody = null;
        this.isChain = false;
        ({soak: this.soak} = options);
      }

      bodyNode() {
        var ref1;
        return (ref1 = this.body) != null ? ref1.unwrap() : void 0;
      }

      elseBodyNode() {
        var ref1;
        return (ref1 = this.elseBody) != null ? ref1.unwrap() : void 0;
      }

      addElse(elseBody) {
        if (this.isChain) {
          this.elseBodyNode().addElse(elseBody);
        } else {
          this.isChain = elseBody instanceof If;
          this.elseBody = this.ensureBlock(elseBody);
          this.elseBody.updateLocationDataIfMissing(elseBody.locationData);
        }
        return this;
      }

      isStatement(o) {
        var ref1;
        return (o != null ? o.level : void 0) === LEVEL_TOP || this.bodyNode().isStatement(o) || ((ref1 = this.elseBodyNode()) != null ? ref1.isStatement(o) : void 0);
      }

      jumps(o) {
        var ref1;
        return this.body.jumps(o) || ((ref1 = this.elseBody) != null ? ref1.jumps(o) : void 0);
      }

      compileNode(o) {
        if (this.isStatement(o)) {
          return this.compileStatement(o);
        } else {
          return this.compileExpression(o);
        }
      }

      makeReturn(res) {
        if (res) {
          this.elseBody || (this.elseBody = new Block([new Literal('void 0')]));
        }
        this.body && (this.body = new Block([this.body.makeReturn(res)]));
        this.elseBody && (this.elseBody = new Block([this.elseBody.makeReturn(res)]));
        return this;
      }

      ensureBlock(node) {
        if (node instanceof Block) {
          return node;
        } else {
          return new Block([node]);
        }
      }

      compileStatement(o) {
        var answer, body, child, cond, exeq, ifPart, indent;
        child = del(o, 'chainChild');
        exeq = del(o, 'isExistentialEquals');
        if (exeq) {
          return new If(this.condition.invert(), this.elseBodyNode(), {
            type: 'if'
          }).compileToFragments(o);
        }
        indent = o.indent + TAB;
        cond = this.condition.compileToFragments(o, LEVEL_PAREN);
        body = this.ensureBlock(this.body).compileToFragments(merge(o, {indent}));
        ifPart = [].concat(this.makeCode("if ("), cond, this.makeCode(") {\n"), body, this.makeCode(`\n${this.tab}}`));
        if (!child) {
          ifPart.unshift(this.makeCode(this.tab));
        }
        if (!this.elseBody) {
          return ifPart;
        }
        answer = ifPart.concat(this.makeCode(' else '));
        if (this.isChain) {
          o.chainChild = true;
          answer = answer.concat(this.elseBody.unwrap().compileToFragments(o, LEVEL_TOP));
        } else {
          answer = answer.concat(this.makeCode("{\n"), this.elseBody.compileToFragments(merge(o, {indent}), LEVEL_TOP), this.makeCode(`\n${this.tab}}`));
        }
        return answer;
      }

      compileExpression(o) {
        var alt, body, cond, fragments;
        cond = this.condition.compileToFragments(o, LEVEL_COND);
        body = this.bodyNode().compileToFragments(o, LEVEL_LIST);
        alt = this.elseBodyNode() ? this.elseBodyNode().compileToFragments(o, LEVEL_LIST) : [this.makeCode('void 0')];
        fragments = cond.concat(this.makeCode(" ? "), body, this.makeCode(" : "), alt);
        if (o.level >= LEVEL_COND) {
          return this.wrapInParentheses(fragments);
        } else {
          return fragments;
        }
      }

      unfoldSoak() {
        return this.soak && this;
      }

    };

    If.prototype.children = ['condition', 'body', 'elseBody'];

    return If;

  })();

  UTILITIES = {
    extend: function(o) {
      return `function(child, parent) { for (var key in parent) { if (${utility('hasProp', o)}.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); return child; }`;
    },
    bind: function() {
      return 'function(fn, me){ return function(){ return fn.apply(me, arguments); }; }';
    },
    indexOf: function() {
      return "[].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; }";
    },
    modulo: function() {
      return "function(a, b) { return (+a % (b = +b) + b) % b; }";
    },
    hasProp: function() {
      return '{}.hasOwnProperty';
    },
    slice: function() {
      return '[].slice';
    }
  };

  LEVEL_TOP = 1;

  LEVEL_PAREN = 2;

  LEVEL_LIST = 3;

  LEVEL_COND = 4;

  LEVEL_OP = 5;

  LEVEL_ACCESS = 6;

  TAB = '  ';

  SIMPLENUM = /^[+-]?\d+$/;

  utility = function(name, o) {
    var ref, root;
    ({root} = o.scope);
    if (name in root.utilities) {
      return root.utilities[name];
    } else {
      ref = root.freeVariable(name);
      root.assign(ref, UTILITIES[name](o));
      return root.utilities[name] = ref;
    }
  };

  multident = function(code, tab) {
    code = code.replace(/\n/g, '$&' + tab);
    return code.replace(/\s+$/, '');
  };

  isLiteralArguments = function(node) {
    return node instanceof IdentifierLiteral && node.value === 'arguments';
  };

  isLiteralThis = function(node) {
    return node instanceof ThisLiteral || (node instanceof Code && node.bound);
  };

  shouldCacheOrIsAssignable = function(node) {
    return node.shouldCache() || (typeof node.isAssignable === "function" ? node.isAssignable() : void 0);
  };

  unfoldSoak = function(o, parent, name) {
    var ifn;
    if (!(ifn = parent[name].unfoldSoak(o))) {
      return;
    }
    parent[name] = ifn.body;
    ifn.body = new Value(parent);
    return ifn;
  };

}).call(this);

  return module.exports;
})();require['./sourcemap'] = (function() {
  var exports = {}, module = {exports: exports};
  // Generated by CoffeeScript 2.0.0-alpha1
(function() {
  var LineMap, SourceMap;

  LineMap = class LineMap {
    constructor(line1) {
      this.line = line1;
      this.columns = [];
    }

    add(column, [sourceLine, sourceColumn], options = {}) {
      if (this.columns[column] && options.noReplace) {
        return;
      }
      return this.columns[column] = {
        line: this.line,
        column,
        sourceLine,
        sourceColumn
      };
    }

    sourceLocation(column) {
      var mapping;
      while (!((mapping = this.columns[column]) || (column <= 0))) {
        column--;
      }
      return mapping && [mapping.sourceLine, mapping.sourceColumn];
    }

  };

  SourceMap = (function() {
    var BASE64_CHARS, VLQ_CONTINUATION_BIT, VLQ_SHIFT, VLQ_VALUE_MASK;

    class SourceMap {
      constructor() {
        this.lines = [];
      }

      add(sourceLocation, generatedLocation, options = {}) {
        var base, column, line, lineMap;
        [line, column] = generatedLocation;
        lineMap = ((base = this.lines)[line] || (base[line] = new LineMap(line)));
        return lineMap.add(column, sourceLocation, options);
      }

      sourceLocation([line, column]) {
        var lineMap;
        while (!((lineMap = this.lines[line]) || (line <= 0))) {
          line--;
        }
        return lineMap && lineMap.sourceLocation(column);
      }

      generate(options = {}, code = null) {
        var buffer, i, j, lastColumn, lastSourceColumn, lastSourceLine, len, len1, lineMap, lineNumber, mapping, needComma, ref, ref1, v3, writingline;
        writingline = 0;
        lastColumn = 0;
        lastSourceLine = 0;
        lastSourceColumn = 0;
        needComma = false;
        buffer = "";
        ref = this.lines;
        for (lineNumber = i = 0, len = ref.length; i < len; lineNumber = ++i) {
          lineMap = ref[lineNumber];
          if (lineMap) {
            ref1 = lineMap.columns;
            for (j = 0, len1 = ref1.length; j < len1; j++) {
              mapping = ref1[j];
              if (!(mapping)) {
                continue;
              }
              while (writingline < mapping.line) {
                lastColumn = 0;
                needComma = false;
                buffer += ";";
                writingline++;
              }
              if (needComma) {
                buffer += ",";
                needComma = false;
              }
              buffer += this.encodeVlq(mapping.column - lastColumn);
              lastColumn = mapping.column;
              buffer += this.encodeVlq(0);
              buffer += this.encodeVlq(mapping.sourceLine - lastSourceLine);
              lastSourceLine = mapping.sourceLine;
              buffer += this.encodeVlq(mapping.sourceColumn - lastSourceColumn);
              lastSourceColumn = mapping.sourceColumn;
              needComma = true;
            }
          }
        }
        v3 = {
          version: 3,
          file: options.generatedFile || '',
          sourceRoot: options.sourceRoot || '',
          sources: options.sourceFiles || [''],
          names: [],
          mappings: buffer
        };
        if (options.inlineMap) {
          v3.sourcesContent = [code];
        }
        return v3;
      }

      encodeVlq(value) {
        var answer, nextChunk, signBit, valueToEncode;
        answer = '';
        signBit = value < 0 ? 1 : 0;
        valueToEncode = (Math.abs(value) << 1) + signBit;
        while (valueToEncode || !answer) {
          nextChunk = valueToEncode & VLQ_VALUE_MASK;
          valueToEncode = valueToEncode >> VLQ_SHIFT;
          if (valueToEncode) {
            nextChunk |= VLQ_CONTINUATION_BIT;
          }
          answer += this.encodeBase64(nextChunk);
        }
        return answer;
      }

      encodeBase64(value) {
        return BASE64_CHARS[value] || (function() {
          throw new Error(`Cannot Base64 encode value: ${value}`);
        })();
      }

    };

    VLQ_SHIFT = 5;

    VLQ_CONTINUATION_BIT = 1 << VLQ_SHIFT;

    VLQ_VALUE_MASK = VLQ_CONTINUATION_BIT - 1;

    BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    return SourceMap;

  })();

  module.exports = SourceMap;

}).call(this);

  return module.exports;
})();require['./coffeescript'] = (function() {
  var exports = {}, module = {exports: exports};
  // Generated by CoffeeScript 2.0.0-alpha1
(function() {
  var Lexer, SourceMap, base64encode, compile, ext, fn1, formatSourcePosition, fs, getSourceMap, helpers, i, len, lexer, packageJson, parser, path, ref, sourceMaps, sources, vm, withPrettyErrors,
    hasProp = {}.hasOwnProperty;

  fs = require('fs');

  vm = require('vm');

  path = require('path');

  ({Lexer} = require('./lexer'));

  ({parser} = require('./parser'));

  helpers = require('./helpers');

  SourceMap = require('./sourcemap');

  packageJson = require('../../package.json');

  exports.VERSION = packageJson.version;

  exports.FILE_EXTENSIONS = ['.coffee', '.litcoffee', '.coffee.md'];

  exports.helpers = helpers;

  base64encode = function(src) {
    switch (false) {
      case typeof Buffer !== 'function':
        return Buffer.from(src).toString('base64');
      case typeof btoa !== 'function':
        return btoa(encodeURIComponent(src).replace(/%([0-9A-F]{2})/g, function(match, p1) {
          return String.fromCharCode('0x' + p1);
        }));
      default:
        throw new Error('Unable to base64 encode inline sourcemap.');
    }
  };

  withPrettyErrors = function(fn) {
    return function(code, options = {}) {
      var err;
      try {
        return fn.call(this, code, options);
      } catch (error) {
        err = error;
        if (typeof code !== 'string') {
          throw err;
        }
        throw helpers.updateSyntaxError(err, code, options.filename);
      }
    };
  };

  sources = {};

  sourceMaps = {};

  exports.compile = compile = withPrettyErrors(function(code, options) {
    var currentColumn, currentLine, encoded, extend, filename, fragment, fragments, generateSourceMap, header, i, j, js, len, len1, map, merge, newLines, ref, ref1, sourceMapDataURI, sourceURL, token, tokens, v3SourceMap;
    ({merge, extend} = helpers);
    options = extend({}, options);
    generateSourceMap = options.sourceMap || options.inlineMap || (options.filename == null);
    filename = options.filename || '<anonymous>';
    sources[filename] = code;
    if (generateSourceMap) {
      map = new SourceMap;
    }
    tokens = lexer.tokenize(code, options);
    options.referencedVars = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = tokens.length; i < len; i++) {
        token = tokens[i];
        if (token[0] === 'IDENTIFIER') {
          results.push(token[1]);
        }
      }
      return results;
    })();
    if (!((options.bare != null) && options.bare === true)) {
      for (i = 0, len = tokens.length; i < len; i++) {
        token = tokens[i];
        if ((ref = token[0]) === 'IMPORT' || ref === 'EXPORT') {
          options.bare = true;
          break;
        }
      }
    }
    fragments = parser.parse(tokens).compileToFragments(options);
    currentLine = 0;
    if (options.header) {
      currentLine += 1;
    }
    if (options.shiftLine) {
      currentLine += 1;
    }
    currentColumn = 0;
    js = "";
    for (j = 0, len1 = fragments.length; j < len1; j++) {
      fragment = fragments[j];
      if (generateSourceMap) {
        if (fragment.locationData && !/^[;\s]*$/.test(fragment.code)) {
          map.add([fragment.locationData.first_line, fragment.locationData.first_column], [currentLine, currentColumn], {
            noReplace: true
          });
        }
        newLines = helpers.count(fragment.code, "\n");
        currentLine += newLines;
        if (newLines) {
          currentColumn = fragment.code.length - (fragment.code.lastIndexOf("\n") + 1);
        } else {
          currentColumn += fragment.code.length;
        }
      }
      js += fragment.code;
    }
    if (options.header) {
      header = `Generated by CoffeeScript ${this.VERSION}`;
      js = `// ${header}\n${js}`;
    }
    if (generateSourceMap) {
      v3SourceMap = map.generate(options, code);
      sourceMaps[filename] = map;
    }
    if (options.inlineMap) {
      encoded = base64encode(JSON.stringify(v3SourceMap));
      sourceMapDataURI = `//# sourceMappingURL=data:application/json;base64,${encoded}`;
      sourceURL = `//# sourceURL=${(ref1 = options.filename) != null ? ref1 : 'coffeescript'}`;
      js = `${js}\n${sourceMapDataURI}\n${sourceURL}`;
    }
    if (options.sourceMap) {
      return {
        js,
        sourceMap: map,
        v3SourceMap: JSON.stringify(v3SourceMap, null, 2)
      };
    } else {
      return js;
    }
  });

  exports.tokens = withPrettyErrors(function(code, options) {
    return lexer.tokenize(code, options);
  });

  exports.nodes = withPrettyErrors(function(source, options) {
    if (typeof source === 'string') {
      return parser.parse(lexer.tokenize(source, options));
    } else {
      return parser.parse(source);
    }
  });

  exports.run = function(code, options = {}) {
    var answer, dir, mainModule, ref;
    mainModule = require.main;
    mainModule.filename = process.argv[1] = options.filename ? fs.realpathSync(options.filename) : '<anonymous>';
    mainModule.moduleCache && (mainModule.moduleCache = {});
    dir = options.filename != null ? path.dirname(fs.realpathSync(options.filename)) : fs.realpathSync('.');
    mainModule.paths = require('module')._nodeModulePaths(dir);
    if (!helpers.isCoffee(mainModule.filename) || require.extensions) {
      answer = compile(code, options);
      code = (ref = answer.js) != null ? ref : answer;
    }
    return mainModule._compile(code, mainModule.filename);
  };

  exports["eval"] = function(code, options = {}) {
    var Module, _module, _require, createContext, i, isContext, js, k, len, o, r, ref, ref1, ref2, ref3, sandbox, v;
    if (!(code = code.trim())) {
      return;
    }
    createContext = (ref = vm.Script.createContext) != null ? ref : vm.createContext;
    isContext = (ref1 = vm.isContext) != null ? ref1 : function(ctx) {
      return options.sandbox instanceof createContext().constructor;
    };
    if (createContext) {
      if (options.sandbox != null) {
        if (isContext(options.sandbox)) {
          sandbox = options.sandbox;
        } else {
          sandbox = createContext();
          ref2 = options.sandbox;
          for (k in ref2) {
            if (!hasProp.call(ref2, k)) continue;
            v = ref2[k];
            sandbox[k] = v;
          }
        }
        sandbox.global = sandbox.root = sandbox.GLOBAL = sandbox;
      } else {
        sandbox = global;
      }
      sandbox.__filename = options.filename || 'eval';
      sandbox.__dirname = path.dirname(sandbox.__filename);
      if (!(sandbox !== global || sandbox.module || sandbox.require)) {
        Module = require('module');
        sandbox.module = _module = new Module(options.modulename || 'eval');
        sandbox.require = _require = function(path) {
          return Module._load(path, _module, true);
        };
        _module.filename = sandbox.__filename;
        ref3 = Object.getOwnPropertyNames(require);
        for (i = 0, len = ref3.length; i < len; i++) {
          r = ref3[i];
          if (r !== 'paths' && r !== 'arguments' && r !== 'caller') {
            _require[r] = require[r];
          }
        }
        _require.paths = _module.paths = Module._nodeModulePaths(process.cwd());
        _require.resolve = function(request) {
          return Module._resolveFilename(request, _module);
        };
      }
    }
    o = {};
    for (k in options) {
      if (!hasProp.call(options, k)) continue;
      v = options[k];
      o[k] = v;
    }
    o.bare = true;
    js = compile(code, o);
    if (sandbox === global) {
      return vm.runInThisContext(js);
    } else {
      return vm.runInContext(js, sandbox);
    }
  };

  exports.register = function() {
    return require('./register');
  };

  if (require.extensions) {
    ref = this.FILE_EXTENSIONS;
    fn1 = function(ext) {
      var base;
      return (base = require.extensions)[ext] != null ? base[ext] : base[ext] = function() {
        throw new Error(`Use CoffeeScript.register() or require the coffeescript/register module to require ${ext} files.`);
      };
    };
    for (i = 0, len = ref.length; i < len; i++) {
      ext = ref[i];
      fn1(ext);
    }
  }

  exports._compileFile = function(filename, sourceMap = false, inlineMap = false) {
    var answer, err, raw, stripped;
    raw = fs.readFileSync(filename, 'utf8');
    stripped = raw.charCodeAt(0) === 0xFEFF ? raw.substring(1) : raw;
    try {
      answer = compile(stripped, {
        filename,
        sourceMap,
        inlineMap,
        sourceFiles: [filename],
        literate: helpers.isLiterate(filename)
      });
    } catch (error) {
      err = error;
      throw helpers.updateSyntaxError(err, stripped, filename);
    }
    return answer;
  };

  lexer = new Lexer;

  parser.lexer = {
    lex: function() {
      var tag, token;
      token = parser.tokens[this.pos++];
      if (token) {
        [tag, this.yytext, this.yylloc] = token;
        parser.errorToken = token.origin || token;
        this.yylineno = this.yylloc.first_line;
      } else {
        tag = '';
      }
      return tag;
    },
    setInput: function(tokens) {
      parser.tokens = tokens;
      return this.pos = 0;
    },
    upcomingInput: function() {
      return "";
    }
  };

  parser.yy = require('./nodes');

  parser.yy.parseError = function(message, {token}) {
    var errorLoc, errorTag, errorText, errorToken, tokens;
    ({errorToken, tokens} = parser);
    [errorTag, errorText, errorLoc] = errorToken;
    errorText = (function() {
      switch (false) {
        case errorToken !== tokens[tokens.length - 1]:
          return 'end of input';
        case errorTag !== 'INDENT' && errorTag !== 'OUTDENT':
          return 'indentation';
        case errorTag !== 'IDENTIFIER' && errorTag !== 'NUMBER' && errorTag !== 'INFINITY' && errorTag !== 'STRING' && errorTag !== 'STRING_START' && errorTag !== 'REGEX' && errorTag !== 'REGEX_START':
          return errorTag.replace(/_START$/, '').toLowerCase();
        default:
          return helpers.nameWhitespaceCharacter(errorText);
      }
    })();
    return helpers.throwSyntaxError(`unexpected ${errorText}`, errorLoc);
  };

  formatSourcePosition = function(frame, getSourceMapping) {
    var as, column, fileLocation, filename, functionName, isConstructor, isMethodCall, line, methodName, source, tp, typeName;
    filename = void 0;
    fileLocation = '';
    if (frame.isNative()) {
      fileLocation = "native";
    } else {
      if (frame.isEval()) {
        filename = frame.getScriptNameOrSourceURL();
        if (!filename) {
          fileLocation = `${frame.getEvalOrigin()}, `;
        }
      } else {
        filename = frame.getFileName();
      }
      filename || (filename = "<anonymous>");
      line = frame.getLineNumber();
      column = frame.getColumnNumber();
      source = getSourceMapping(filename, line, column);
      fileLocation = source ? `${filename}:${source[0]}:${source[1]}` : `${filename}:${line}:${column}`;
    }
    functionName = frame.getFunctionName();
    isConstructor = frame.isConstructor();
    isMethodCall = !(frame.isToplevel() || isConstructor);
    if (isMethodCall) {
      methodName = frame.getMethodName();
      typeName = frame.getTypeName();
      if (functionName) {
        tp = as = '';
        if (typeName && functionName.indexOf(typeName)) {
          tp = `${typeName}.`;
        }
        if (methodName && functionName.indexOf(`.${methodName}`) !== functionName.length - methodName.length - 1) {
          as = ` [as ${methodName}]`;
        }
        return `${tp}${functionName}${as} (${fileLocation})`;
      } else {
        return `${typeName}.${methodName || '<anonymous>'} (${fileLocation})`;
      }
    } else if (isConstructor) {
      return `new ${functionName || '<anonymous>'} (${fileLocation})`;
    } else if (functionName) {
      return `${functionName} (${fileLocation})`;
    } else {
      return fileLocation;
    }
  };

  getSourceMap = function(filename) {
    var answer;
    if (sourceMaps[filename] != null) {
      return sourceMaps[filename];
    } else if (sourceMaps['<anonymous>'] != null) {
      return sourceMaps['<anonymous>'];
    } else if (sources[filename] != null) {
      answer = compile(sources[filename], {
        filename: filename,
        sourceMap: true,
        literate: helpers.isLiterate(filename)
      });
      return answer.sourceMap;
    } else {
      return null;
    }
  };

  Error.prepareStackTrace = function(err, stack) {
    var frame, frames, getSourceMapping;
    getSourceMapping = function(filename, line, column) {
      var answer, sourceMap;
      sourceMap = getSourceMap(filename);
      if (sourceMap != null) {
        answer = sourceMap.sourceLocation([line - 1, column - 1]);
      }
      if (answer != null) {
        return [answer[0] + 1, answer[1] + 1];
      } else {
        return null;
      }
    };
    frames = (function() {
      var j, len1, results;
      results = [];
      for (j = 0, len1 = stack.length; j < len1; j++) {
        frame = stack[j];
        if (frame.getFunction() === exports.run) {
          break;
        }
        results.push(`    at ${formatSourcePosition(frame, getSourceMapping)}`);
      }
      return results;
    })();
    return `${err.toString()}\n${frames.join('\n')}\n`;
  };

}).call(this);

  return module.exports;
})();require['./browser'] = (function() {
  var exports = {}, module = {exports: exports};
  // Generated by CoffeeScript 2.0.0-alpha1
(function() {
  var CoffeeScript, compile, runScripts,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  CoffeeScript = require('./coffeescript');

  CoffeeScript.require = require;

  compile = CoffeeScript.compile;

  CoffeeScript["eval"] = function(code, options = {}) {
    if (options.bare == null) {
      options.bare = true;
    }
    return eval(compile(code, options));
  };

  CoffeeScript.run = function(code, options = {}) {
    options.bare = true;
    options.shiftLine = true;
    return Function(compile(code, options))();
  };

  if (typeof window === "undefined" || window === null) {
    return;
  }

  if ((typeof btoa !== "undefined" && btoa !== null) && (typeof JSON !== "undefined" && JSON !== null)) {
    compile = function(code, options = {}) {
      options.inlineMap = true;
      return CoffeeScript.compile(code, options);
    };
  }

  CoffeeScript.load = function(url, callback, options = {}, hold = false) {
    var xhr;
    options.sourceFiles = [url];
    xhr = window.ActiveXObject ? new window.ActiveXObject('Microsoft.XMLHTTP') : new window.XMLHttpRequest();
    xhr.open('GET', url, true);
    if ('overrideMimeType' in xhr) {
      xhr.overrideMimeType('text/plain');
    }
    xhr.onreadystatechange = function() {
      var param, ref;
      if (xhr.readyState === 4) {
        if ((ref = xhr.status) === 0 || ref === 200) {
          param = [xhr.responseText, options];
          if (!hold) {
            CoffeeScript.run(...param);
          }
        } else {
          throw new Error(`Could not load ${url}`);
        }
        if (callback) {
          return callback(param);
        }
      }
    };
    return xhr.send(null);
  };

  runScripts = function() {
    var coffees, coffeetypes, execute, fn, i, index, j, len, s, script, scripts;
    scripts = window.document.getElementsByTagName('script');
    coffeetypes = ['text/coffeescript', 'text/literate-coffeescript'];
    coffees = (function() {
      var j, len, ref, results;
      results = [];
      for (j = 0, len = scripts.length; j < len; j++) {
        s = scripts[j];
        if (ref = s.type, indexOf.call(coffeetypes, ref) >= 0) {
          results.push(s);
        }
      }
      return results;
    })();
    index = 0;
    execute = function() {
      var param;
      param = coffees[index];
      if (param instanceof Array) {
        CoffeeScript.run(...param);
        index++;
        return execute();
      }
    };
    fn = function(script, i) {
      var options, source;
      options = {
        literate: script.type === coffeetypes[1]
      };
      source = script.src || script.getAttribute('data-src');
      if (source) {
        options.filename = source;
        return CoffeeScript.load(source, function(param) {
          coffees[i] = param;
          return execute();
        }, options, true);
      } else {
        options.filename = script.id && script.id !== '' ? script.id : `coffeescript${(i !== 0 ? i : '')}`;
        options.sourceFiles = ['embedded'];
        return coffees[i] = [script.innerHTML, options];
      }
    };
    for (i = j = 0, len = coffees.length; j < len; i = ++j) {
      script = coffees[i];
      fn(script, i);
    }
    return execute();
  };

  if (window.addEventListener) {
    window.addEventListener('DOMContentLoaded', runScripts, false);
  } else {
    window.attachEvent('onload', runScripts);
  }

}).call(this);

  return module.exports;
})();
    return require['./coffeescript'];
  }();

  if (typeof define === 'function' && define.amd) {
    define(function() { return CoffeeScript; });
  } else {
    root.CoffeeScript = CoffeeScript;
  }
}(this));