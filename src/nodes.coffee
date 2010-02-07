exports.Node: -> @values: arguments; @name: this.constructor.name

exports.Expressions       : -> @name: this.constructor.name; @values: arguments
exports.LiteralNode       : -> @name: this.constructor.name; @values: arguments
exports.ReturnNode        : -> @name: this.constructor.name; @values: arguments
exports.CommentNode       : -> @name: this.constructor.name; @values: arguments
exports.CallNode          : -> @name: this.constructor.name; @values: arguments
exports.ExtendsNode       : -> @name: this.constructor.name; @values: arguments
exports.ValueNode         : -> @name: this.constructor.name; @values: arguments
exports.AccessorNode      : -> @name: this.constructor.name; @values: arguments
exports.IndexNode         : -> @name: this.constructor.name; @values: arguments
exports.RangeNode         : -> @name: this.constructor.name; @values: arguments
exports.SliceNode         : -> @name: this.constructor.name; @values: arguments
exports.AssignNode        : -> @name: this.constructor.name; @values: arguments
exports.OpNode            : -> @name: this.constructor.name; @values: arguments
exports.CodeNode          : -> @name: this.constructor.name; @values: arguments
exports.SplatNode         : -> @name: this.constructor.name; @values: arguments
exports.ObjectNode        : -> @name: this.constructor.name; @values: arguments
exports.ArrayNode         : -> @name: this.constructor.name; @values: arguments
exports.PushNode          : -> @name: this.constructor.name; @values: arguments
exports.ClosureNode       : -> @name: this.constructor.name; @values: arguments
exports.WhileNode         : -> @name: this.constructor.name; @values: arguments
exports.ForNode           : -> @name: this.constructor.name; @values: arguments
exports.TryNode           : -> @name: this.constructor.name; @values: arguments
exports.ThrowNode         : -> @name: this.constructor.name; @values: arguments
exports.ExistenceNode     : -> @name: this.constructor.name; @values: arguments
exports.ParentheticalNode : -> @name: this.constructor.name; @values: arguments
exports.IfNode            : -> @name: this.constructor.name; @values: arguments

exports.Expressions.wrap  : (values) -> @values: values
