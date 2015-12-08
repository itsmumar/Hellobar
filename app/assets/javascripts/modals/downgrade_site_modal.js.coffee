class @DowngradeSiteModal extends Modal

  modalName: 'downgrade-site'

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#downgrade-template").html())
    @$modal = $(@template({}))
    @$modal.appendTo($("body"))

    super(@$modal)
