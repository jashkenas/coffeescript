(function(){
  exports.Node = function Node() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.values = arguments;
    __a = this.name = this.constructor.name;
    return Node === this.constructor ? this : __a;
  };
  exports.Expressions = function Expressions() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return Expressions === this.constructor ? this : __a;
  };
  exports.LiteralNode = function LiteralNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return LiteralNode === this.constructor ? this : __a;
  };
  exports.ReturnNode = function ReturnNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ReturnNode === this.constructor ? this : __a;
  };
  exports.CommentNode = function CommentNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return CommentNode === this.constructor ? this : __a;
  };
  exports.CallNode = function CallNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return CallNode === this.constructor ? this : __a;
  };
  exports.ExtendsNode = function ExtendsNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ExtendsNode === this.constructor ? this : __a;
  };
  exports.ValueNode = function ValueNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ValueNode === this.constructor ? this : __a;
  };
  exports.AccessorNode = function AccessorNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return AccessorNode === this.constructor ? this : __a;
  };
  exports.IndexNode = function IndexNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return IndexNode === this.constructor ? this : __a;
  };
  exports.RangeNode = function RangeNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return RangeNode === this.constructor ? this : __a;
  };
  exports.SliceNode = function SliceNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return SliceNode === this.constructor ? this : __a;
  };
  exports.AssignNode = function AssignNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return AssignNode === this.constructor ? this : __a;
  };
  exports.OpNode = function OpNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return OpNode === this.constructor ? this : __a;
  };
  exports.CodeNode = function CodeNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return CodeNode === this.constructor ? this : __a;
  };
  exports.SplatNode = function SplatNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return SplatNode === this.constructor ? this : __a;
  };
  exports.ObjectNode = function ObjectNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ObjectNode === this.constructor ? this : __a;
  };
  exports.ArrayNode = function ArrayNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ArrayNode === this.constructor ? this : __a;
  };
  exports.PushNode = function PushNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return PushNode === this.constructor ? this : __a;
  };
  exports.ClosureNode = function ClosureNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ClosureNode === this.constructor ? this : __a;
  };
  exports.WhileNode = function WhileNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return WhileNode === this.constructor ? this : __a;
  };
  exports.ForNode = function ForNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ForNode === this.constructor ? this : __a;
  };
  exports.TryNode = function TryNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return TryNode === this.constructor ? this : __a;
  };
  exports.ThrowNode = function ThrowNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ThrowNode === this.constructor ? this : __a;
  };
  exports.ExistenceNode = function ExistenceNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ExistenceNode === this.constructor ? this : __a;
  };
  exports.ParentheticalNode = function ParentheticalNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ParentheticalNode === this.constructor ? this : __a;
  };
  exports.IfNode = function IfNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return IfNode === this.constructor ? this : __a;
  };
  exports.Expressions.wrap = function wrap(values) {
    return this.values = values;
  };
})();