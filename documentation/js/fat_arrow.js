(function(){
  var Account;
  Account = function Account(customer, cart) {
    var __a;
    this.customer = customer;
    this.cart = cart;
    __a = $('.shopping_cart').bind('click', (function(__this) {
      var __func = function(event) {
        return this.customer.purchase(this.cart);
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
    return Account === this.constructor ? this : __a;
  };
})();