(function(){
  var coffeescript, factories, loader;
  // This (javascript) file is generated from lib/coffee_script/narwhal/loader.coffee
  coffeescript = null;
  factories = {
  };
  loader = {
    // Reload the coffee-script environment from source.
    reload: function(topId) {
      coffeescript = coffeescript || require('coffee-script');
      return (factories[topId] = function() {
        return coffeescript;
      });
    },
    // Ensure that the coffee-script environment is loaded.
    load: function(topId) {
      return factories[topId] = factories[topId] || this.reload(topId);
    }
  };
  require.loader.loaders.unshift([".coffee", loader]);
})();