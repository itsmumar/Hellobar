$ ->
  $('[data-toggle="tooltip"]').tooltip()

  $(".subscription_link").click ->
    siteId = $(@).data("siteid")
    $(".edit_site_form[data-site-id='" + siteId + "']").toggleClass("hidden")

  $(".free_days_link").click ->
    siteId = $(@).data("siteid")
    $(".free_days_site_form[data-site-id='" + siteId + "']").toggleClass("hidden")

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

  $(".edit_site_form input[id^=subscription_subscription]").change (e) ->
    paid = /^(Pro|Growth|Elite)$/.test($(e.target).val())
    $(e.target).closest("form").find("#subscription_trial_period").prop("disabled", !paid)
