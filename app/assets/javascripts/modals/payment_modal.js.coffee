class @PaymentModal extends Modal

  modalName: "payment-account"
  modalTemplate: -> $('script#payment-modal-template').html()
  paymentDetailsTemplate: -> $('script#cc-payment-details-template').html()

  constructor: (@options = {}) ->
    @userPaymentMethods = @fetchUserPaymentMethods({siteID: window.siteID})
    @$modal = @buildModal()
    @_bindInteractions()

  buildModal: ->
    Handlebars.registerPartial('cc-payment-details', @paymentDetailsTemplate())
    template = Handlebars.compile(@modalTemplate())
    $(template(
      errors: @options.errors
      package: @options
      currentPaymentDetails: @options.currentPaymentDetails
      userPaymentMethods: @options.userPaymentMethods
      isAnnual: @isAnnual()
    ))

  isAnnual: ->
    @options.cycle == 'yearly'

  open: ->
    $('body').append(@$modal)
    super

  _bindInteractions: ->
    @_bindChangePlan()
    @_bindFormSubmission()
    @_bindLinkedPayment()

  _bindChangePlan: ->
    # re-open the upgrade modal to allow selecting a different plan
    @$modal.find('.different-plan').on 'click', (event) =>
      new UpgradeAccountModal().open()
      @close()

  _bindFormSubmission: ->
    # bind submission of payment details
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
          content = ''

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
    !isNaN(@_linkedDetailId())

  _linkedDetailId: ->
    parseInt(@$modal.find('select#linked-detail').val())

  _method: ->
    if @_isUsingLinkedPaymentMethod() || @options.currentPaymentDetails
      'PUT'
    else
      'POST'

  _url: ->
    if @_method() == 'POST'
      "/payment_methods/"
    else # inject the payment_method_id OF the selected payment detail
      paymentMethodId = if @_isUsingLinkedPaymentMethod()
        window.userPaymentMethods.filter((method) =>
          method.current_details.data.id == @_linkedDetailId()
        )[0].id
      else
        window.currentPaymentDetails.data.payment_method_id

      "/payment_methods/#{paymentMethodId}"

  _renderAlert: (content) ->
    template = Handlebars.compile($('script#alert-template').html())
    alert = template({type: 'error', content: content})
    @$modal.find('.modal-block').prepend(alert)

  _removeAlerts: ->
    @$modal.find('.alert').remove()
