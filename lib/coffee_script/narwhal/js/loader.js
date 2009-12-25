(function(){

  // This (javascript) file is generated from lib/coffee_script/narwhal/loader.coffee
  var coffeescript = null;
  var factories = {
  };
  var loader = {
    // Reload the coffee-script environment from source.
    reload: function(topId, path) {
      coffeescript = coffeescript || require('coffee-script');
      factories[topId] = coffeescript.makeNarwhalFactory(path);
      return factories[topId];
    },
    // Ensure that the coffee-script environment is loaded.
    load: function(topId, path) {
      return factories[topId] = factories[topId] || this.reload(topId, path);
    }
  };
  require.loader.loaders.unshift([".coffee", loader]);
})();