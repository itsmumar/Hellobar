class @PaymentModal extends Modal

  modalName: "payment-account"
  modalTemplate: -> $('script#payment-modal-template').html()
  paymentDetailsTemplate: -> $('script#cc-payment-details-template').html()
  linkedMethodsTemplate: -> $("script#linked-methods-template").html()
  currentPaymentMethod: null

  constructor: (@options = {}) ->
    @$modal = @buildModal()

    @$modal.on 'load', -> $(this).addClass('loading')
    @$modal.on 'complete', -> $(this).removeClass('loading').finish()

    @fetchUserPaymentMethods(window.siteID)

    @_bindInteractions()

  buildModal: ->
    Handlebars.registerPartial('cc-payment-details', @paymentDetailsTemplate())
    template = Handlebars.compile(@modalTemplate())
    $(template(
      errors: @options.errors
      package: @options.package
      isAnnual: @_isAnnual()
      isMonthly: @_isMonthly()
      isFree: @_isFree()
      siteName: @options.site.display_name
      upgradeBenefit: @options.upgradeBenefit
    ))

  open: ->
    $('body').append(@$modal)
    @source = @options.source

    super

  close: ->
    $form = @$modal.find('form')
    filledOutInputs = $form.find(":input:text:not([type=hidden])").filter( (index) ->
      @value && 0 != @value.length
    ).length

    super

  fetchUserPaymentMethods: (siteID) ->
    @$modal.trigger('load') # indicate we need to do more work

    paymentUrl = "/payment_methods/"
    paymentUrl += "?site_id=#{siteID}" if siteID

    $.getJSON(paymentUrl).then (response) =>
      if response.payment_methods.length > 0
        template = Handlebars.compile(@paymentDetailsTemplate())

        @currentPaymentMethod = response.payment_methods.filter((paymentMethod) ->
          paymentMethod.current_site_payment_method
        )[0] || {}

        html = $(template(
          package: @options.package
          currentPaymentDetails: @currentPaymentMethod.current_details
          siteName: @options.site.display_name
        ))

        # update the template with linked payment methods
        html.find('#linked-payment-methods')
            .html(@_buildLinkedPaymentMethods(response.payment_methods))


      # replace the payment details fragment
      # with linked payment methods & current payment info
      $paymentDetails = $('#payment-details')
      $paymentDetails.html(html)
      $paymentDetails.find('.site-select-form').hide() if window.siteID
      @_bindLinkedPayment() # make sure we still toggle on linking payment
      @_bindFormSubmission() # make sure we can still submit with the new form!

      if @options.site.current_subscription && @options.site.current_subscription.payment_method_details_id
        $paymentDetails.find("select#linked-detail").val(@options.site.current_subscription.payment_method_details_id).change()

    , -> # on failed retreival
      console.log "Couldn't retreive user payments for #{siteID}"

    @$modal.trigger('complete') # all done.

  _buildLinkedPaymentMethods: (paymentMethods) ->
    template = Handlebars.compile(@linkedMethodsTemplate())
    $(template({paymentMethods: paymentMethods}))

  _bindInteractions: ->
    @_bindChangePlan()
    @_bindFormSubmission()
    @_bindDynamicStateLength()

  # re-open the upgrade modal to allow selecting a different plan
  _bindChangePlan: ->
    @$modal.find('.different-plan').on 'click', (event) =>
      options =
        site: @options.site
        successCallback: @options.successCallback
        upgradeBenefit: @options.upgradeBenefit
        source: "Change Plan"

      new UpgradeAccountModal(options).open()
      @close()

  # bind submission of payment details
  _bindFormSubmission: ->
    @_unbindFormSubmission() # clear any existing event bindings to make sure we only have one at a time

    @$modal.find('a.submit').on 'click', (event) =>
      @_unbindFormSubmission() # prevent double submissions
      @_clearErrors()
      @$modal.find("a.submit").addClass("cancel")

      $form = @$modal.find('form')

      $.ajax
        dataType: 'json'
        url: @_url()
        method: @_method()
        data: $form.serialize()
        success: (data, status, xhr) =>
          options =
            successCallback: @options.successCallback
            data: data
            isFree: @_isFree()
            siteName: @options.site.display_name

          new PaymentConfirmationModal(options).open()
          @close()
        error: (xhr, status, error) =>
          @_bindFormSubmission() # rebind so they can enter valid info
          @$modal.find("a.submit").removeClass("cancel")

          if xhr.responseJSON
            @_displayErrors(xhr.responseJSON.errors)

  _bindDynamicStateLength: ->
    @$modal.find('#payment_method_details_country').change (event) =>
      if event.target.value == 'US'
        @$modal.find('.cc-state input').attr('maxlength', 2)
      else
        @$modal.find('.cc-state input').attr('maxlength', 3)

    @$modal.find('#payment_method_details_country').trigger('change')

  _unbindFormSubmission: ->
    @$modal.find('a.submit').off('click')

  _bindLinkedPayment: ->
    @$modal.find('select#linked-detail').on 'change', (event) =>
      $paymentDetail = $(event.target)

      if @_isUsingLinkedPaymentMethod()
        @_hideDetailsForm()
      else
        @_showDetailsForm()

  # disables the details form elements
  # triggered when a user wants to link an existing payment method
  _hideDetailsForm: ->
    @$modal.find('form .details-fields').hide()
    @$modal.find('.details-fields input, .details-fields select')
         .val('')
         .attr('disabled', true)

  _showDetailsForm: ->
    @$modal.find('form .details-fields').show()
    @$modal.find('.details-fields input, .details-fields select')
           .attr('disabled', false)

  _isUsingLinkedPaymentMethod: ->
    !isNaN(@_linkedPaymentMethodId())

  _isAnnual: ->
    @options.package.schedule == 'yearly'

  _isMonthly: ->
    !@_isAnnual()

  _isFree: ->
    !@options.package.requires_payment_method &&
      if @_isAnnual() then @options.package.yearly_amount == 0 else @options.package.monthly_amount == 0

  _linkedPaymentMethodId: ->
    parseInt(@$modal.find('select#linked-detail').val())

  _method: ->
    if @_isUsingLinkedPaymentMethod() || @_isFree()
      'PUT'
    else
      'POST'

  _url: ->
    if @_isUsingLinkedPaymentMethod()
      "/payment_methods/" + @_linkedPaymentMethodId()
    else if @_isFree()
      "/payment_methods/" + @currentPaymentMethod.current_details.payment_method_id
    else
      "/payment_methods"
