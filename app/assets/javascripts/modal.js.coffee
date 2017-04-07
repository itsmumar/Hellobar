class @Modal

  # $modal: jQuery selector of the .modal-wrapper
  constructor: (@$modal) ->

  # renders the modal via CSS
  open: ->
    @_bindCloseEvents(@close)
    @_bindErrorEvents()

    setTimeout (=>
      @$modal.addClass("show-modal #{@modalName}-modal")
      @$modal.trigger("open")
    ), 0

    # Track the open if possible
    if @modalName && @source
      InternalTracking.track_current_person(@modalName, { source: @source })

  close: ->
    @$modal.removeClass('show-modal')

    # wait a bit before removing from the DOM
    setTimeout (=>
      @$modal.remove()
    ), 500

  _render: (templateId, context = {}) ->
    template = Handlebars.compile($("#" + templateId).html())
    $(template(context))

  _bindCloseEvents: (callback) ->
    @_bindEscape(callback)
    @_bindClickOnClose(callback)
    @_bindClickOutsideTarget(callback)

  _bindEscape: (callback) ->
    $(document).on 'keyup', (event) =>
      callback.call(this) if event.keyCode == 27

  _bindClickOnClose: (callback) ->
    @$modal.find('a.cancel, .modal-block > .icon-close').on 'click', (event) =>
      event.preventDefault()
      @_clearErrors()
      callback.call(this)

  _bindClickOutsideTarget: (callback) ->
    @$modal.on 'click', (event) =>
      @_clearErrors()
      callback.call(this) if $(event.target).hasClass('modal-wrapper')

  _bindUpgradePackageSelection: (defOptions = {}, schedule = 'yearly')->
    @$modal.find('.button').on 'click', (event) =>
      unless !!$(event.target).attr("disabled")
        packageData = JSON.parse(event.target.dataset.package)
        packageData.schedule = schedule

        options =
          source: "package-selected"
          package: packageData
          site: defOptions.site
          successCallback: defOptions.successCallback
          upgradeBenefit: defOptions.upgradeBenefit

        new PaymentModal(options).open()

      @close(true)

  #-----------  Error State Helpers  -----------#

  _bindErrorEvents: ->
    @$modal.find('.flash-block').on 'click', '.icon-close', =>
      @_clearErrors()

  _displayErrors: (errors) ->
    return unless errors.length > 0
    $('.modal-wrapper').animate({ scrollTop: 0 })
    errorText = errors.reduce (a, b) -> "#{a}<br>#{b}"
    @$modal.find('.modal-block .flash-block').prepend(errorText).addClass('alert show')

  _clearErrors: ->
    @$modal.find('.modal-block .flash-block').html('<i class="icon-close"></i>').removeClass('alert show')
