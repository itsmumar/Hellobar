class @RegistrationModal extends Modal

  $modal: null # will retreive content for this on open()

  modalName: 'registration'

  fetchModal: ->
    $.get('/modals/registration')

  open: ->
    @fetchModal().done (markup) =>
      $('body').append(markup) # needs to be in the DOM to render!
      @$modal = $('.modal-wrapper:last')
      super

  _bindCloseEvents: ->
    null # dont allow them to close the modal due to hard page refresh
