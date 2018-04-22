screen =
  width: 1200
  ratio: 16/9

Object.defineProperty screen, 'height',
  get: ->
    this.width / this.ratio
  set: (val) ->
    this.width = val * this.ratio
