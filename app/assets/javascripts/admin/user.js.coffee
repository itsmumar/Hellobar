deliverPasswordReset = (ahref) ->
  $link = $(ahref)

  $.ajax
    method: 'POST'
    url: $link.attr('href')
    data:
      user: { email: $link.data('user-email') }
    success: ->
      $link.text('Sent!')

$ ->
  $('a#reset_password').on 'click', (event) ->
    event.preventDefault()
    deliverPasswordReset(this)

  $(".refund_link").click ->
    $(@).hide()
    $("#edit_bill_recurring_" + $(@).data("id")).toggleClass("hidden")
    $(@).closest("tr").toggleClass( "hilight" )

  $(".subscription_link").click ->
    $(@).hide()
    $("#edit_site_" + $(@).data("id")).toggleClass("hidden")

  $(".add-invoice-info").click (e) ->
    e.preventDefault()
    $(@).parent().next().toggleClass("hidden")

  $(".regenerate_link").click (e) ->
    e.preventDefault()

    url = $(@).data("url")
    $.ajax(
      url,
      {
        dataType: "json"
        type: "POST"
        error: (jqXHR, textStatus, errorThrown) ->
          console.log(jqXHR, textStatus, errorThrown)
          alert(
            "Error!\n" +
            JSON.parse(jqXHR.responseText).message
          )
        success: (data, textStatus, jqXHR) ->
          alert(data.message)
      }
    )
