$ ->
  $("tr.see-more a").click (e) ->
    $(e.target).toggleClass("seeing-more")
    $("tr.more-top-performers").toggle()

  # allow users to edit/update their payment information
  $('a#update-cc-details, a#change-billing-cycle').click ->
    options =
      type: window.subscriptionValues.name.toLowerCase(),
      cycle: window.subscriptionValues.schedule
      paymentDetails: window.paymentDetails.data
    new PaymentModal(options).open()
