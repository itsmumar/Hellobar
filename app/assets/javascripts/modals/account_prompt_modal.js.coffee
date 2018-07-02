class @AccountPromptModal extends Modal

  modalName: "account-prompt"

  constructor: (@options = {}) ->
    @template ?= Handlebars.compile($("#account-prompt-modal-template").html())

    @$modal ?= $(@template(@options))
    @$modal.appendTo($("body"))

    super(@$modal)

  open: ->
    @_rerouteErrors()
    @_bindSubmit()
    @_detectTimezone()

    super

  close: ->
    false

  _rerouteErrors: ->
    flash = $('.global-content .flash-block')

    if flash.length
      message = flash.text()

      # do not reroute the flash to tell users to clear their cache
      if message.indexOf('cache') == -1
        flash.remove()
        @_displayErrors([message])

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
