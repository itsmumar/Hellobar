class @Modal

  # $modal: jQuery selector of the .modal-wrapper
  constructor: (@$modal) ->

  # renders the modal via CSS
  open: ->
    @_bindCloseEvents(@close)

    setTimeout (=>
      @$modal.addClass("show-modal #{@modalName}-modal")
      @$modal.trigger("open")
    ), 0

  close: ->
    @$modal.removeClass('show-modal')

    # wait a bit before removing from the DOM
    setTimeout (=>
      @$modal.remove()
    ), 500

  _bindCloseEvents: (callback) ->
    @_bindEscape(callback)
    @_bindClickOnClose(callback)
    @_bindClickOutsideTarget(callback)

  _bindEscape: (callback) ->
    $(document).on 'keyup', (event) =>
      callback.call(this) if event.keyCode == 27

  _bindClickOnClose: (callback) ->
    @$modal.find('a.cancel').on 'click', (event) =>
      event.preventDefault()
      callback.call(this)

  _bindClickOutsideTarget: (callback) ->
    @$modal.on 'click', (event) =>
      callback.call(this) if $(event.target).hasClass('modal-wrapper')
