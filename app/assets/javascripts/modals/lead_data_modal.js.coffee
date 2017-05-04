
class @LeadDataModal extends Modal
  canClose: false
  modalName: 'lead-data'
  allowedCountries: ['US', 'AU', 'GB', 'CA']

  constructor: (@applicationSettings, @options = {}) ->
    return unless @applicationSettings.lead_data
    leadData = @applicationSettings.lead_data
    data = {}
    data.industries = leadData.industries.map (industry) => {name: industry, value: industry.toLowerCase()}
    data.roles = leadData.job_roles.map (role) => {name: role, value: role.toLowerCase()}
    data.companySizes = leadData.company_sizes.map (size) => {name: size, value: size.toLowerCase()}
    data.trafficItems = leadData.traffic_items.map (size) => {name: size, value: size.toLowerCase()}
    data.challenges = leadData.challenges.map (challenge) => {name: challenge, value: challenge.toLowerCase()}
    data.countryCodes = leadData.country_codes.filter((country) => @allowedCountries.indexOf(country.code) != -1)
    data.currentUser = @applicationSettings.current_user

    @$modal = @_render('lead-data-template', data)
    @$modal.appendTo($("body"))
    @$firstForm = @$modal.find('form.screen-1')
    @$secondForm = @$modal.find('form.screen-2')
    @_bindButtons()
    @_bindInputs()
    super(@$modal)

  checkCountryAndOpen: ->
    return unless @applicationSettings.lead_data
    @_getCountryCode().then (response) =>
      if (@allowedCountries.indexOf(response.countryCode) != -1)
        @open()

  close: ->
    return unless @_validateFirstScreen() && @_validateSecondScreen() && @canClose
    @_saveData()
    super

  _getCountryCode: ->
    if (countryCode = localStorage.getItem('countryCode'))
      return $.when({countryCode})

    $.ajax
      url: @applicationSettings.geolocation_url
      crossDomain: true
      dataType: 'json'
    .done (response) ->
      localStorage.setItem('countryCode', response.countryCode)

  _saveData: ->
    data = @$firstForm.serializeArray().reduce @_reducer, {}
    data = @$secondForm.serializeArray().reduce @_reducer, data
    data.phone_number = formatE164(data.country, data.phone_number)

    $.post('/leads', lead: data).then ->
      message = $('<div class="flash-block error">Your submission was successful. A representative from our team will contact you soon.</div>')
      $('body').prepend(message)
      setTimeout (-> message.addClass('show')), 500
      setTimeout (-> message.removeClass('show')), 10000

  _reducer: (result, item) ->
    result[item.name] = item.value
    result

  _validateFirstScreen: ->
    if @$firstForm.get(0).reportValidity
      @$firstForm.get(0).reportValidity()
    @$firstForm.get(0).checkValidity()

  _validateSecondScreen: ->
    if @$secondForm.get(0).reportValidity
      @$secondForm.get(0).reportValidity()
    @$secondForm.get(0).checkValidity()

  _bindInputs: ->
    @$modal.find('.js-not-interesting').on 'change', =>
      @$modal.find('.js-phone-number').removeAttr('required')
      @canClose = true
      @close()

    @$modal.find('.js-interesting').on 'change', =>
      @$modal.find('.js-phone-number').attr('required', 'required').show()

    @$modal.find('select[name="country"]').on 'change', (event) =>
      countryCode = $(event.target).val()
      example = formatLocal(countryCode, exampleMobileNumber(countryCode))
      placeholder = "e.g. #{example}"
      @$modal.find('input[name="phone_number"]').val('').attr('placeholder', placeholder)

    @$modal.find('input[name="phone_number"]').on 'keyup change', (event) =>
      phoneNumber = $(event.target).val()
      countryCode = $('.js-phone-number [name="country"]').val()

      if phoneNumber == "" || !isValidNumber(phoneNumber, countryCode)
        @canClose = false
        @$modal.find('.js-close').hide()
      else
        @canClose = true
        @$modal.find('.js-close').show()

  _bindButtons: ->
    @$modal.find('.radio-group .btn').on 'click', ->
      $(this).parent().find('.btn').removeClass('active')
      $(this).addClass('active')

    @$modal.find('.js-close').on 'click', =>
      @close()

    $('.js-prev-screen').on 'click', =>
      @$firstForm.show()
      @$secondForm.hide()
      @$modal.find('.js-prev-screen').hide()
      @$modal.find('.js-close').hide()
      @$modal.find('.js-next-screen').show()

    $('.js-next-screen').on 'click', =>
      if @_validateFirstScreen()
        @$firstForm.hide()
        @$secondForm.show()
        @$modal.find('.js-prev-screen').show()
        @$modal.find('.js-close').show() if @canClose
        @$modal.find('.js-next-screen').hide()
