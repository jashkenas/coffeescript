# This (javascript) file is generated from lib/coffee_script/narwhal/loader.cs

coffeescript: null

CoffeeScriptLoader: =>
  loader: {}
  factories: {}

  loader.reload: topId, path =>
    coffeescript ||: require('coffee-script')
    # print("loading objective-j: " + topId + " (" + path + ")");
    factories[topId]: coffeescript.make_narwhal_factory(path).

  loader.load: topId, path =>
    loader.reload(topId, path) unless factories.hasOwnProperty(topId)
    factories[topId].

  loader.

require.loader.loaders.unshift([".cs", CoffeeScriptLoader()])
