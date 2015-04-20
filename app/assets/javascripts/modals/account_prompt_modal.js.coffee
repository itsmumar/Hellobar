class @AccountPromptModal extends Modal

  modalName: "account-prompt"

  constructor: (@options = {}) ->
    @template ?= Handlebars.compile($("#account-prompt-modal-template").html())

    @$modal ?= $(@template(@options))
    @$modal.appendTo($("body"))

    super(@$modal)

  open: ->
    InternalTracking.track_current_person("registration_viewed_form")

    @_rerouteErrors()
    @_attachTracking()
    @_bindSubmit()
    @_detectTimezone()

    super

  close: ->
    false

  _rerouteErrors: ->
    flash = $('.global-content .flash-block')

    if flash.length
      message = flash.text()
      flash.remove()
      @_displayErrors([message])

  _attachTracking: ->
    @$modal.find("input#user_email").keyup (event) =>
      unless @trackedUserEmail
        InternalTracking.track_current_person("registration_entered_email")

      @trackedUserEmail = true

    @$modal.find("input#user_password").keyup (event) =>
      unless @trackedUserPassword
        InternalTracking.track_current_person("registration_entered_password")

      @trackedUserPassword = true

    @$modal.find("form").submit (event) =>
      InternalTracking.track_current_person("registration_submitted_form")

  _bindSubmit: ->
    @$modal.find("form").submit (event) =>
      event.preventDefault()
      $form = $(event.target)

      $.ajax
        dataType: 'json'
        url: $form.attr("action")
        type: $form.attr("method")
        data: $form.serialize()
        success: (data, status, xhr) =>
          window.location = data.redirect_to
        error: (xhr, status, error) =>
          @_displayErrors([xhr.responseJSON["error_message"]])

  _detectTimezone: ->
    @$modal.find("#user_timezone").val(jstz.determine().name())
