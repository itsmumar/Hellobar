class @AlternateAccountPromptModal extends AccountPromptModal

  modalName: "alternate-account-prompt"

  constructor: (@options = {}) ->
    @options.siteURL = @options.siteURL.replace("http://", "")
    @options.headerClass = HB_ACCOUNT_CREATION_VARIATION

    @template = Handlebars.compile($("#alternate-account-prompt-modal-template").html())

    @$modal = $(@template(@options))

    super(@$modal)

  open: ->
    @_attachTZBehavior()
    @_attachInputBehavior()

    super

    $("#user_email").focus()

  _attachTZBehavior: ->
    $("#user_timezone").change (event) ->
      $select = $(event.target)
      tz = $select.find("option:selected").text()
      $(".tz-brief a").html(tz.replace(/\(GMT.*\d\d\)\s/, ""))

    $(".tz-brief a").click ->
      $(".tz-brief").hide()
      $(".tz-select").show()

    setTimeout (->
      $("#user_timezone").trigger("change")
    ), 250

  _attachInputBehavior: ->
    $("#user_email").keyup (event) ->
      $input = $(event.target)

      if $input.val().length < 1
        $input.closest("div").addClass("has-error")
      else
        $input.closest("div").removeClass("has-error")

    $("#user_email").trigger("keyup")

    $("#user_password").keyup (event) ->
      $input = $(event.target)

      if $input.val().length < 8
        $input.closest("div").addClass("has-error")
      else
        $input.closest("div").removeClass("has-error")

    $("#user_password").trigger("keyup")


    $("#user_email, #user_password").keyup (event) =>
      $submit = @$modal.find("input[type=submit]")

      if $("#user_email").val().length > 0 && $("#user_password").val().length >= 7
        $submit.prop("disabled", false)
      else
        $submit.prop("disabled", true)
