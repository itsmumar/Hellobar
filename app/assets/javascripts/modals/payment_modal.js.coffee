class @PaymentModal extends Modal

  modalName: "payment-account"
  modalTemplate: -> $('script#payment-modal-template').html()

  constructor: (@options = {}) ->
    @$modal = @buildModal()
    @_bindInteractions()

  buildModal: ->
    template = Handlebars.compile(@modalTemplate())
    $(template({errors: @options.errors, package: @options, isAnnual: @isAnnual()}))

  isAnnual: ->
    @options.cycle == 'yearly'

  open: ->
    $('body').append(@$modal)
    super

  _bindInteractions: ->
    # re-open the upgrade modal to allow selecting a different plan
    @$modal.find('.different-plan').on 'click', (event) =>
      new UpgradeAccountModal().open()
      @close()

    # bind submission of payment details
    @$modal.find('a.submit').on 'click', (event) =>
      $form = @$modal.find('form')

      $.ajax
        dataType: 'json'
        url: $form.attr('action')
        method: $form.attr('method')
        data: $form.serialize() + "&site_id=#{window.siteID}"
        success: (data, status, xhr) ->
          # now we need to open the success window
        error: (xhr, status, error) ->
          errors = xhr.responseJSON.errors
          alert errors.join(", ")

      # async submission of the form to the backend
