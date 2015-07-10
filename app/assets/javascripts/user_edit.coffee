$ ->

  $("#user-edit #show-password-form, #user-update #show-password-form").click (e) ->
    $( this ).hide()
    $(".password-form .hidden").removeClass("hidden")
