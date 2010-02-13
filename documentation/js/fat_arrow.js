(function(){
  var Account;
  Account = function Account(customer, cart) {
    this.customer = customer;
    this.cart = cart;
    return $('.shopping_cart').bind('click', (function(__this) {
      var __func = function(event) {
        return this.customer.purchase(this.cart);
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
  };
})();