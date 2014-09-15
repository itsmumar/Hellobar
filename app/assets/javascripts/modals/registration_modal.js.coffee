class @RegistrationModal extends Modal

  $modal: null # will retreive content for this on open()

  modalName: 'registration'

  fetchModal: ->
    $.get('/modals/registration')

  open: ->
    @fetchModal().done (markup) =>
      $('body').append(markup) # needs to be in the DOM to render!
      @$modal = $('.modal-wrapper:last')
      @_bindSubmit()
      super

  _bindCloseEvents: ->
    null # dont allow them to close the modal due to hard page refresh

  _bindSubmit: ->
    modal = this

    @$modal.find('form').on 'submit', (event) ->
      event.preventDefault()
      modal._removeAlert()

      $.ajax
        dataType: 'json'
        url: @action
        type: @method
        data: $(this).serialize()
        success: (data, status, xhr) ->
          modal.close()
        error: (xhr, status, error) ->
          console.log "Something went wrong: #{error}"

          content = ''

          if xhr.responseJSON
            for key in Object.keys(xhr.responseJSON)
              content += "#{key} #{xhr.responseJSON[key].join()}"
              content += "<br />"
          else
            content = error

          modal._renderAlert(content)

  _renderAlert: (content) ->
    template = Handlebars.compile($('script#alert-template').html())
    alert = template({type: 'error', content: content})
    @$modal.find('.modal-block').prepend(alert)

  _removeAlert: ->
    @$modal.find('.alert').remove()
