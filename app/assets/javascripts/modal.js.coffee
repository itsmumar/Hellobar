class @Modal
  # $modal: jQuery selector of the .modal-wrapper
  constructor: (@$modal) ->
    @_bindCloseEvents(@close)

  # renders the modal via CSS
  open: ->
    @$modal.addClass('show-modal')

  # closes the modal via CSS and disables all event bindings
  close: ->
    @$modal.removeClass('show-modal')
           .off() # unbind all modal events

  _bindCloseEvents: (callback) ->
    @_bindEscape(callback)
    @_bindClickOnClose(callback)
    @_bindClickOutsideTarget(callback)

  _bindEscape: (callback) ->
    $(document).on 'keyup', (event) =>
      callback.call(this) if event.keyCode == 27

  _bindClickOnClose: (callback) ->
    @$modal.find('a.cancel').on 'click', (event) =>
      callback.call(this)

  _bindClickOutsideTarget: (callback) ->
    @$modal.on 'click', (event) =>
      callback.call(this) if $(event.target).hasClass('modal-wrapper')
