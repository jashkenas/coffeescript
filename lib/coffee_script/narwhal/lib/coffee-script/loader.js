(function(){
  var coffeescript, factories, loader;
  // This (javascript) file is generated from lib/coffee_script/narwhal/loader.coffee
  coffeescript = null;
  factories = {
  };
  loader = {
    // Reload the coffee-script environment from source.
    reload: function(topId, path) {
      coffeescript = coffeescript || require('coffee-script');
      return (factories[topId] = coffeescript.makeNarwhalFactory(path));
    },
    // Ensure that the coffee-script environment is loaded.
    load: function(topId, path) {
      return factories[topId] = factories[topId] || this.reload(topId, path);
    }
  };
  require.loader.loaders.unshift([".coffee", loader]);
})();