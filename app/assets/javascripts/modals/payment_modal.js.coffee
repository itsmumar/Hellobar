class @PaymentModal extends Modal

  modalName: "payment-account"
  modalTemplate: -> $('script#payment-modal-template').html()
  creditCardDetailsTemplate: -> $('script#credit-card-details-template').html()
  linkedCreditCardsTemplate: -> $("script#linked-credit-cards-template").html()
  currentCreditCard: null

  constructor: (@options = {}) ->
    @$modal = @buildModal()

    @$modal.on 'load', -> $(this).addClass('loading')
    @$modal.on 'complete', -> $(this).removeClass('loading').finish()

    @fetchUserCreditCards(window.siteID)
    @_bindInteractions()

  buildModal: ->
    Handlebars.registerPartial('credit-card-details', @creditCardDetailsTemplate())
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
    super

  close: ->
    $form = @$modal.find('form')
    filledOutInputs = $form.find(":input:text:not([type=hidden])").filter( (index) ->
      @value && 0 != @value.length
    ).length

    super

  chooseCreditCard: () ->

  fetchUserCreditCards: (siteID) ->
    @$modal.trigger('load') # indicate we need to do more work

    url = "/credit_cards/"
    url += "?site_id=#{siteID}" if siteID

    $.getJSON(url).then (response) =>
      @current_credit_card_id =
        response.current_credit_card_id ||
        @options.credit_card_id ||
        @options.site.current_subscription.credit_card_id

      if response.credit_cards.length > 0
        template = Handlebars.compile(@creditCardDetailsTemplate())

        @currentCreditCard = response.credit_cards.filter((creditCard) =>
          creditCard.id == @current_credit_card_id
        )[0] || {}

        html = $(template(
          package: @options.package
          currentCreditCard: @currentCreditCard
          siteName: @options.site.display_name
        ))

        # update the template with linked credit cards
        html.find('#linked-credit-cards')
          .html(@_buildLinkedCreditCards(response.credit_cards))


      # replace the credit card details fragment
      # with linked credit card
      $creditCardDetails = $('#credit-card-details')
      $creditCardDetails.html(html)
      $creditCardDetails.find('.site-select-form').hide() if window.siteID
      @_bindFormSubmission() # make sure we can still submit with the new form!

      $creditCardDetails.find("select#linked-credit-card").val(@current_credit_card_id) if @current_credit_card_id

    , -> # on failed retreival
      console.log "Couldn't retreive user credit cards for #{siteID}"

    @$modal.trigger('complete') # all done.

  _buildLinkedCreditCards: (creditCards) ->
    template = Handlebars.compile(@linkedCreditCardsTemplate())
    $(template(creditCards: creditCards))

  _bindInteractions: ->
    @_bindNewCreditCard()
    @_bindChangePlan()
    @_bindFormSubmission()
    @_bindDynamicStateLength()

  _bindNewCreditCard: ->
    @$modal.on 'click', '#add-new-credit-card', (event) =>
      event.preventDefault()
      new NewCreditCardModal(site: @options.site, open_payment_form: true).open()
      @close()


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

  # bind submission of credit card details
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
        method: 'PUT'
        data: $form.serialize()
        success: (data, status, xhr) =>
          options =
            successCallback: @options.successCallback
            data: data
            isFree: @_isFree()
            siteName: @options.site.display_name

          @_pushGTMEvents(data)

          new PaymentConfirmationModal(options).open()
          @close()
        error: (xhr, status, error) =>
          @_bindFormSubmission() # rebind so they can enter valid info
          @$modal.find("a.submit").removeClass("cancel")

          if xhr.responseJSON
            @_displayErrors(xhr.responseJSON.errors)

  _pushGTMEvents: (billData) ->
    return if !window?.dataLayer?.push || !billData.is_upgrade

    window.dataLayer.push
      event: 'GAEvent'
      category: 'Subscription'
      action: 'upgrade'
      label: billData.subscription_name + '-' + billData.subscription_schedule

    window.dataLayer.push
      event: 'GATransaction'
      transactionId: billData.id
      transactionTotal: billData.amount
      transactionProducts: [
        {
          sku: billData.subscription_name + '-' + billData.subscription_schedule
          name: billData.subscription_name
          category: billData.subscription_schedule
          price: billData.amount
          quantity: 1
        }
      ]

  _bindDynamicStateLength: ->
    @$modal.on 'change', '#credit_card_country', (event) =>
      if event.target.value == 'US'
        @$modal.find('.cc-state input').attr('maxlength', 2)
      else
        @$modal.find('.cc-state input').attr('maxlength', 3)

    @$modal.find('#credit_card_country').trigger('change')

  _unbindFormSubmission: ->
    @$modal.find('a.submit').off('click')

  _bindLinkedCreditCards: ->
    @$modal.find('select#linked-credit-card').on 'change', (event) =>
      $creditCard = $(event.target)

      if @_isUsingLinkedCreditCard()
        @_hideCreditCardForm()
      else
        @_showCreditCardForm()

  _isAnnual: ->
    @options.package.schedule == 'yearly'

  _isMonthly: ->
    !@_isAnnual()

  _isFree: ->
    !@options.package.requires_credit_card &&
      if @_isAnnual() then @options.package.yearly_amount == 0 else @options.package.monthly_amount == 0

  _linkedCreditCardId: ->
    parseInt(@$modal.find('select#linked-credit-card').val()) || @currentCreditCard.id

  _url: ->
    "/subscription/?credit_card_id=" + @_linkedCreditCardId()

