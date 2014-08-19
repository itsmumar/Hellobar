class @Modal
  
  # $modal: jQuery selector of the .modal-wrapper
  constructor: (@$modal) ->

  # renders the modal via CSS
  open: ->
    @_bindCloseEvents(@close)
    @$modal.addClass("show-modal #{@modalName}-modal")

  # closes the modal via CSS and disables all event bindings
  close: ->
    @$modal.removeClass('show-modal')
           .off() # unbind all modal events
           .find("*")
           .off() # unbind all child events
           .delay(330).removeClass("#{@modalName}-modal")

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
