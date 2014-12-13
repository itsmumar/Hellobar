$ ->
  $(".refund_link").click ->
    $(@).hide()
    $("#edit_bill_recurring_" + $(@).data("id")).show()
    $(@).closest("tr").toggleClass( "hilight" );
