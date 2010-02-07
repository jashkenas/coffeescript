(function(){
  exports.Node = function Node() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    __a = this.values = arguments;
    return Node === this.constructor ? this : __a;
  };
  exports.Node.wrap = function wrap(values) {
    return this.values = values;
  };
  exports.Expressions = exports.Node;
  exports.LiteralNode = exports.Node;
  exports.ReturnNode = exports.Node;
  exports.CommentNode = exports.Node;
  exports.CallNode = exports.Node;
  exports.ExtendsNode = exports.Node;
  exports.ValueNode = exports.Node;
  exports.AccessorNode = exports.Node;
  exports.IndexNode = exports.Node;
  exports.RangeNode = exports.Node;
  exports.SliceNode = exports.Node;
  exports.AssignNode = exports.Node;
  exports.OpNode = exports.Node;
  exports.CodeNode = exports.Node;
  exports.SplatNode = exports.Node;
  exports.ObjectNode = exports.Node;
  exports.ArrayNode = exports.Node;
  exports.PushNode = exports.Node;
  exports.ClosureNode = exports.Node;
  exports.WhileNode = exports.Node;
  exports.ForNode = exports.Node;
  exports.TryNode = exports.Node;
  exports.ThrowNode = exports.Node;
  exports.ExistenceNode = exports.Node;
  exports.ParentheticalNode = exports.Node;
  exports.IfNode = exports.Node;
})();