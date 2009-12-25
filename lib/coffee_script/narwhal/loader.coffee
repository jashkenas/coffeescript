# This (javascript) file is generated from lib/coffee_script/narwhal/loader.coffee

coffeescript: null
factories: {}

loader: {

  # Reload the coffee-script environment from source.
  reload: topId, path =>
    coffeescript ||= require('coffee-script')
    factories[topId]: coffeescript.makeNarwhalFactory(path).

  # Ensure that the coffee-script environment is loaded.
  load: topId, path =>
    factories[topId] ||= this.reload(topId, path).

}

require.loader.loaders.unshift([".coffee", loader])
