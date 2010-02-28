(function(){
  String.prototype.dasherize = function dasherize() {
    return this.replace(/_/g, "-");
  };
})();
