class @NewCreditCardModal extends Modal

  modalName: "new-credit-card"
  modalTemplate: -> $('script#new-credit-card-modal-template').html()

  constructor: (@options = {}) ->
    @$modal = @buildModal()

    @$modal.on 'load', -> $(this).addClass('loading')
    @$modal.on 'complete', -> $(this).removeClass('loading').finish()

    @_bindInteractions()

  buildModal: ->
    template = Handlebars.compile(@modalTemplate())
    $(template(
      errors: @options.errors
      package: @options.package
      siteName: @options.site.display_name
      upgradeBenefit: @options.upgradeBenefit
    ))

  open: ->
    $('body').append(@$modal)
    super

  _bindInteractions: ->
    @_bindFormSubmission()
    @_bindDynamicStateLength()

  _bindFormSubmission: ->
    @$modal.on 'click', 'a.submit', (event) =>
      @_unbindFormSubmission() # prevent double submissions
      @_clearErrors()
      @$modal.find("a.submit").addClass("cancel")

      $form = @$modal.find('form')

      $.ajax
        dataType: 'json'
        url: @_url()
        method: 'POST'
        data: $form.serialize()
        success: (data, status, xhr) =>
          options =
            package: window.site.current_subscription
            site: window.site
            credit_card_id: data.id
          new PaymentModal(options).open()
          @close()

        error: (xhr, status, error) =>
          @_bindFormSubmission() # rebind so they can enter valid info
          @$modal.find("a.submit").removeClass("cancel")

          if xhr.responseJSON
            @_displayErrors(xhr.responseJSON.errors)

  _bindDynamicStateLength: ->
    @$modal.on 'change', '#credit_card_country', (event) =>
      if event.target.value == 'US'
        @$modal.find('.cc-state input').attr('maxlength', 2)
      else
        @$modal.find('.cc-state input').attr('maxlength', 3)

    @$modal.find('#credit_card_country').trigger('change')

  _unbindFormSubmission: ->
    @$modal.find('a.submit').off('click')

  _url: ->
    '/credit_cards/?site_id=' + @options.site.id

