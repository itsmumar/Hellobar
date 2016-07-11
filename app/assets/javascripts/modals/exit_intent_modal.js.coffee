class @ExitIntentModal extends Modal

  modalName: 'exit-intent'

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#exit-intent-modal-template").html())
    @$modal = $(@template())
    @$modal.appendTo($("body"))

    super(@$modal)

  open: ->
    @_bindPackageSelection()
    super

  _bindPackageSelection: ->
    @$modal.find('.button').on 'click', (event) =>
      unless !!$(event.target).attr("disabled")
        packageData = JSON.parse(event.target.dataset.package)
        packageData.schedule = 'yearly'

        options =
          source: "package-selected"
          package: packageData
          site: @options.site
          successCallback: @options.successCallback
          upgradeBenefit: @options.upgradeBenefit

        new PaymentModal(options).open()

      @close(true)
