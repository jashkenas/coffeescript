(function(){
  var coffeescript = null;
  var CoffeeScriptLoader = function() {
    var loader = {
    };
    var factories = {
    };
    loader.reload = function(topId, path) {
      coffeescript = coffeescript || require('coffee-script');
      // print("loading objective-j: " + topId + " (" + path + ")");
      factories[topId] = coffeescript.make_narwhal_factory(path);
      return factories[topId];
    };
    loader.load = function(topId, path) {
      if (!(factories.hasOwnProperty(topId))) {
        loader.reload(topId, path);
      }
      return factories[topId];
    };
    return loader;
  };
  require.loader.loaders.unshift([".cs", CoffeeScriptLoader()]);
})();
