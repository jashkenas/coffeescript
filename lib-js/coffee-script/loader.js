var coffeescript = null;

function CoffeeScriptLoader() {
    var loader = {};
    var factories = {};
    
    loader.reload = function(topId, path) {
        if (!coffeescript) coffeescript = require("coffee-script");
        
        //print("loading objective-j: " + topId + " (" + path + ")");
        factories[topId] = coffeescript.make_narwhal_factory(path);
    }
    
    loader.load = function(topId, path) {
        if (!factories.hasOwnProperty(topId))
            loader.reload(topId, path);
        return factories[topId];
    }
    
    return loader;
};

require.loader.loaders.unshift([".cs", CoffeeScriptLoader()]);
