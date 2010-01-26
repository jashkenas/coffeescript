Account: (customer, cart) =>
  this.customer: customer
  this.cart: cart

  $('.shopping_cart').bind 'click', (event) ==>
    this.customer.purchase this.cart