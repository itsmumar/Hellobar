class @PaymentModal extends Modal

  modalName: "payment-account"
  modalTemplate: -> $('script#payment-modal-template').html()
  paymentDetailsTemplate: -> $('script#cc-payment-details-template').html()
  linkedMethodsTemplate: -> $("script#linked-methods-template").html()

  constructor: (@options = {}) ->
    @fetchUserPaymentMethods(window.siteID) unless @options.addPaymentMethod
    @options.currentPaymentDetails = null if @options.addPaymentMethod
    @$modal = @buildModal()
    @_bindInteractions()

  buildModal: ->
    Handlebars.registerPartial('cc-payment-details', @paymentDetailsTemplate())
    template = Handlebars.compile(@modalTemplate())
    $(template(
      errors: @options.errors
      package: @options.package
      currentPaymentDetails: @options.currentPaymentDetails
      isAnnual: @isAnnual()
    ))

  isAnnual: ->
    @options.package.cycle == 'yearly'

  open: ->
    $('body').append(@$modal)
    super

  fetchUserPaymentMethods: (siteID) ->
    paymentUrl = "/payment_methods/"
    paymentUrl += "?site_id=#{siteID}" if siteID

    $.getJSON(paymentUrl).then (response) =>
      # on success, update the payment detail modal
      if response.payment_methods.length > 0
        template = Handlebars.compile(@linkedMethodsTemplate())
        html = $(template({paymentMethods: response.payment_methods}))
        @$modal.find('#linked-payment-methods').html(html)
        @_bindLinkedPayment()
    , -> # on failed retreival
      console.log "Couldn't retreive user payments for #{siteID}"

  _bindInteractions: ->
    @_bindChangePlan()
    @_bindFormSubmission()

  # re-open the upgrade modal to allow selecting a different plan
  _bindChangePlan: ->
    @$modal.find('.different-plan').on 'click', (event) =>
      new UpgradeAccountModal().open()
      @close()

  # bind submission of payment details
  _bindFormSubmission: ->
    @$modal.find('a.submit').on 'click', (event) =>
      @_unbindFormSubmission() # prevent double submissions
      @_removeAlerts()

      $form = @$modal.find('form')

      $.ajax
        dataType: 'json'
        url: @_url()
        method: @_method()
        data: $form.serialize() + "&site_id=#{window.siteID}"
        success: (data, status, xhr) =>
          alert "Successfully paid!"
          @close()
          # TODO:
          # now we need to open the success window
          window.location = window.location # temp solution: hard refresh of page
          # update the currentSubscription and paymentDetails window objects
        error: (xhr, status, error) =>
          @_bindFormSubmission() # rebind so they can enter valid info

          if xhr.responseJSON
            content = xhr.responseJSON.errors.join(', ')
            @_renderAlert(content)

  _unbindFormSubmission: ->
    @$modal.find('a.submit').off('click')

  _bindLinkedPayment: ->
    @$modal.find('select#linked-detail').on 'change', (event) =>
      $paymentDetail = $(event.target)

      if @_isUsingLinkedPaymentMethod()
        @_disableDetailsForm()
      else
        @_enableDetailsForm()

  # disables the details form elements
  # triggered when a user wants to link an existing payment method
  _disableDetailsForm: ->
    @$modal.find('form input:not("[name^=billing]")')
         .val('')
         .attr('disabled', true)

  _enableDetailsForm: ->
    @$modal.find('form input')
           .attr('disabled', false)

  _isUsingLinkedPaymentMethod: ->
    !isNaN(@_linkedPaymentMethodId())

  _linkedPaymentMethodId: ->
    parseInt(@$modal.find('select#linked-detail').val())

  _method: ->
    if @_isUsingLinkedPaymentMethod() || @options.currentPaymentDetails
      'PUT'
    else
      'POST'

  _url: ->
    if @options.addPaymentMethod
      "/payment_methods"
    else if @_isUsingLinkedPaymentMethod()
      "/payment_methods/" + @_linkedPaymentMethodId()
    else if @options.currentPaymentDetails
      "/payment_methods/" + @options.currentPaymentDetails.payment_method_id
    else
      "/payment_methods"

  _renderAlert: (content) ->
    template = Handlebars.compile($('script#alert-template').html())
    alert = template({type: 'error', content: content})
    @$modal.find('.modal-block').prepend(alert)

  _removeAlerts: ->
    @$modal.find('.alert').remove()
