$ ->

  $("#user-edit #show-password-form, #user-update #show-password-form").click (e) ->
    $( this ).hide()
    $(".password-fields .hidden").removeClass("hidden")
    $("#user_email").prop('disabled', false)

  $("#user-edit .personal-form, #user-update .personal-form").submit (event) ->
    if $("#user_current_password").length == 0 && $("#user_password").val().length
      confirm("After you add a password, you will no longer be able to login through Google.")
