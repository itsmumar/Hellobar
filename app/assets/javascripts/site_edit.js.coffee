$ ->
  $(".toggle-site-invoice-information").click (event) ->
    event.preventDefault()
    $("#site_invoice_information, .invoice-information").toggleClass("hidden")
