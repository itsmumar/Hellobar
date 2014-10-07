class @PaymentModal extends Modal

  modalName: "payment-account"
  modalTemplate: -> $('script#payment-modal-template').html()
  paymentDetailsTemplate: -> $('script#cc-payment-details-template').html()

  constructor: (@options = {}) ->
    @paymentDetails = @options.paymentDetails || {}
    @$modal = @buildModal()
    @_bindInteractions()

  buildModal: ->
    Handlebars.registerPartial('cc-payment-details', @paymentDetailsTemplate())
    template = Handlebars.compile(@modalTemplate())
    $(template({errors: @options.errors, package: @options, paymentDetails: @paymentDetails, isAnnual: @isAnnual()}))

  isAnnual: ->
    @options.cycle == 'yearly'

  open: ->
    $('body').append(@$modal)
    super

  _bindInteractions: ->
    @_bindChangePlan()
    @_bindFormSubmission()

  _bindChangePlan: ->
    # re-open the upgrade modal to allow selecting a different plan
    @$modal.find('.different-plan').on 'click', (event) =>
      new UpgradeAccountModal().open()
      @close()

  _bindFormSubmission: ->
    # bind submission of payment details
    @$modal.find('a.submit').on 'click', (event) =>
      @_unbindFormSubmission() # prevent double submissions

      $form = @$modal.find('form')

      $.ajax
        dataType: 'json'
        url: $form.attr('action')
        method: $form.attr('method')
        data: $form.serialize() + "&site_id=#{window.siteID}"
        success: (data, status, xhr) =>
          alert "Successfully paid!"
          @close()
          # TODO:
          # now we need to open the success window
          window.location = window.location # temp solution: hard refresh of page
          # update the subscriptionValues and paymentDetails window objects
        error: (xhr, status, error) =>
          @_bindFormSubmission() # rebind so they can enter valid info
          errors = xhr.responseJSON.errors
          alert errors.join(", ")

  _unbindFormSubmission: ->
    @$modal.find('a.submit').off('click')
