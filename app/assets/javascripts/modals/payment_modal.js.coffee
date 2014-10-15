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
      isAnnual: @isAnnual(),
      siteName: @options.site.display_name
    ))

  isAnnual: ->
    @options.package.schedule == 'yearly'

  open: ->
    $('body').append(@$modal)
    super

  fetchUserPaymentMethods: (siteID) ->
    return if @options.addPaymentMethod # we don't need to do anything!

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
      @_bindLinkedPayment() # make sure we still toggle on linking payment
      @_bindFormSubmission() # make sure we can still submit with the new form!

    , -> # on failed retreival
      console.log "Couldn't retreive user payments for #{siteID}"

    @$modal.trigger('complete') # all done.

  _buildLinkedPaymentMethods: (paymentMethods) ->
    template = Handlebars.compile(@linkedMethodsTemplate())
    $(template({paymentMethods: paymentMethods}))

  _bindInteractions: ->
    @_bindChangePlan()
    @_bindFormSubmission()

  # re-open the upgrade modal to allow selecting a different plan
  _bindChangePlan: ->
    @$modal.find('.different-plan').on 'click', (event) =>
      new UpgradeAccountModal({site: @options.site}).open()
      @close()

  # bind submission of payment details
  _bindFormSubmission: ->
    @_unbindFormSubmission() # clear any existing event bindings to make sure we only have one at a time

    @$modal.find('a.submit').on 'click', (event) =>
      @_unbindFormSubmission() # prevent double submissions
      @_removeAlerts()
      @$modal.find("a.submit").addClass("cancel")

      $form = @$modal.find('form')

      $.ajax
        dataType: 'json'
        url: @_url()
        method: @_method()
        data: $form.serialize() + "&site_id=#{window.siteID}"
        success: (data, status, xhr) =>
          alert "Successfully paid!"
          @close()
          # TODO: open the success window
          window.location.reload(true) # temp solution: hard refresh of page
        error: (xhr, status, error) =>
          @_bindFormSubmission() # rebind so they can enter valid info
          @$modal.find("a.submit").removeClass("cancel")

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
    if @_isUsingLinkedPaymentMethod()
      'PUT'
    else
      'POST'

  _url: ->
    if @options.addPaymentMethod
      "/payment_methods"
    else if @_isUsingLinkedPaymentMethod()
      "/payment_methods/" + @_linkedPaymentMethodId()
    else if @currentPaymentMethod && @currentPaymentMethod.currentPaymentDetails
      "/payment_methods/" + @currentPaymentMethod.currentPaymentDetails.payment_method_id
    else
      "/payment_methods"

  _renderAlert: (content) ->
    template = Handlebars.compile($('script#alert-template').html())
    alert = template({type: 'error', content: content})
    @$modal.find('.modal-block').prepend(alert)

  _removeAlerts: ->
    @$modal.find('.alert').remove()
