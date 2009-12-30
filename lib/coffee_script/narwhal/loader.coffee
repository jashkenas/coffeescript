# This (javascript) file is generated from lib/coffee_script/narwhal/loader.coffee

coffeescript: null
factories: {}

loader: {

  # Reload the coffee-script environment from source.
  reload: topId =>
    coffeescript ||= require('coffee-script')
    factories[topId]: => coffeescript

  # Ensure that the coffee-script environment is loaded.
  load: topId =>
    factories[topId] ||= this.reload(topId)

}

require.loader.loaders.unshift([".coffee", loader])
