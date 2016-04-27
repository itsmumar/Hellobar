$ ->
  $(".toggle-site-invoice-information").click (event) ->
    event.preventDefault()
    if $("#site_invoice_information").is(":visible")
      $("#site_invoice_information").addClass("hide")
      $(".invoice-information").removeClass("hide")
    else
      $("#site_invoice_information").removeClass("hide")
      $(".invoice-information").addClass("hide")
