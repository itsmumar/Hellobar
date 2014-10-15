$ ->
  $("tr.see-more a").click (e) ->
    $(e.target).toggleClass("seeing-more")
    $("tr.more-top-performers").toggle()

  # allow users to edit/update their payment information
  $('a.update-cc-details').click ->
    options =
      package: window.site.current_subscription
      addPaymentMethod: $(this).hasClass('add-payment-method')
      site: window.site
    new PaymentModal(options).open()
