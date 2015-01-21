class @AccountPromptModal extends Modal

  modalName: "account-prompt"

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#account-prompt-modal-template").html())
    @$modal = $(@template())
    @$modal.appendTo($("body"))

    super(@$modal)

  open: ->
    InternalTracking.track_current_person("registration_viewed_form")

    @_rerouteErrors()
    @_attachTracking()

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
