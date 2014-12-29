$ ->
  $(".refund_link").click ->
    $(@).hide()
    $("#edit_bill_recurring_" + $(@).data("id")).toggleClass("hidden")
    $(@).closest("tr").toggleClass( "hilight" );

  $(".subscription_link").click ->
    $(@).hide()
    $("#edit_site_" + $(@).data("id")).toggleClass("hidden")
