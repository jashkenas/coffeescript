
exports.AstTamer = class AstTamer

    constructor: (rest...) ->
    	
    transform: (x) ->
      x.walkTaming()
      x
