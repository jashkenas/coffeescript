var FILE = require("file");
var OS = require("os");

exports.run = function(args) {
    // TODO: non-REPL
    
    args.shift();
    
    if (args.length) {
        require(FILE.absolute(args[0]));
        return;
    }
    
    while (true)
    {
        try {
            system.stdout.write("cs> ").flush();

            var result = exports.cs_eval(require("readline").readline());

            if (result !== undefined)
                print(result);
                
        } catch (e) {
            print(e);
        }
    }
}

// executes the coffee-script Ruby program to convert from CoffeeScript to Objective-J.
// eventually this will hopefully be replaced by a JavaScript program.
var coffeePath = FILE.path(module.path).dirname().dirname().join("bin", "coffee-script");

exports.compileFile = function(path) {
    var coffee = OS.popen([coffeePath, "--print", path]);

    if (coffee.wait() !== 0)
        throw new Error("coffee compiler error");

    return coffee.stdout.read();
}

exports.compile = function(source) {
    var coffee = OS.popen([coffeePath, "-"]);

    coffee.stdin.write(source).flush().close();

    if (coffee.wait() !== 0)
        throw new Error("coffee compiler error");

    return coffee.stdout.read();
}

// these two functions are equivalent to objective-j's objj_eval/make_narwhal_factory.
// implemented as a call to coffee and objj_eval/make_narwhal_factory
exports.cs_eval = function(source) {
    init();
    
    var code = exports.compile(source);
    
    // strip the function wrapper, we add our own.
    // TODO: this is very fragile
    code = code.split("\n").slice(1,-2).join("\n");
    
    return eval(code);
}

exports.make_narwhal_factory = function(path) {
    init();
    
    var code = exports.compileFile(path);
    
    // strip the function wrapper, we add our own.
    // TODO: this is very fragile
    code = code.split("\n").slice(1,-2).join("\n");
    
    var factoryText = "function(require,exports,module,system,print){" + code + "/**/\n}";

    if (system.engine === "rhino")
        return Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(global, factoryText, path, 0, null);
    
    // eval requires parenthesis, but parenthesis break compileFunction.
    else
        return eval("(" + factoryText + ")");
}


var init = function() {
    // make sure it's only done once
    init = function(){}
}