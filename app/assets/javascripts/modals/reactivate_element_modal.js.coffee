class @ReactivateElementModal extends Modal

  modalName: 'reactivate-element'

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#reactivate-template").html())
    @$modal = $(@template({}))
    @$modal.appendTo($("body"))
    @site = @options.site

    super(@$modal)

    @$modal.find(".upgrade-plan").click (evt) =>
      evt.preventDefault()
      @$modal.close
      options =
        site: @site
        source: $(this).data('source')
      new UpgradeAccountModal(options).open()

