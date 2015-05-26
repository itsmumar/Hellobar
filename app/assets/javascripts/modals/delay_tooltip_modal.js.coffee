class @DelayTooltipModal extends Modal

  modalName: 'delay-tooltip'

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#delay-tooltip-modal-template").html())
    @$modal = $(@template())
    @$modal.appendTo($("body"))

    super(@$modal)
