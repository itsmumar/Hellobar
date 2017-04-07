class @LeadDataModal extends Modal
  canClose: true
  modalName: 'lead-data'

  constructor: (@options = {}) ->
    industries = ["Church", "Corporate", "Community", "Custom App", "Event", "eCommerce", "Education", "Entertainment",
      "Financial", "Gaming Poker", "Hair Salon", "Hotel", "Industrial", "Law Firm", "Medical/Health",
      "Marketing Services", "Mobile App Developer", "Music Artists", "NPO", "Organizational", "Personal App",
      "Professional Services", "Practitioner", "Publishing", "Real Estate", "Restaurant", "Small Business",
      "Sell Products", "Sell Services", "Social", "Spa/Gym", "Speaker", "Sports", "Travel", "Messing Around", "Other"]
    industries = industries.map (industry) => {name: industry, value: industry.toLowerCase()}

    roles = ["Creative Designer", "Developer", "Marketing", "Management", "Student", "Other"]
    roles = roles.map (role) => {name: role, value: role.toLowerCase()}

    companySizes = ["Just Me", "1-10", "11-25", "25-50", "50+"]
    companySizes = companySizes.map (size) => {name: size, value: size.toLowerCase()}

    trafficItems = ["1 000", "10 000", "50 000", "100 000", "100 000+"]
    trafficItems = trafficItems.map (size) => {name: size, value: size.toLowerCase()}

    challenges = [
      {name: "Capture More Emails", value: "more_emails"},
      {name: "Generate More Sales", value: "more_sales"},
      {name: "Conversion Optimization", "conversion_optimization"}
    ]

    @$modal = @_render('lead-data-template', {industries, roles, companySizes, trafficItems, challenges, currentUser})
    @$modal.appendTo($("body"))
    @_bind_buttons()
    @_bind_inputs()
    @firstForm = @$modal.find('form.screen-1')
    @secondForm = @$modal.find('form.screen-2')
    super(@$modal)

  close: ->
    return unless @_validateSecondScreen() && @canClose
    @_saveData()
    super

  _saveData: ->
    data = @firstForm.serializeArray().reduce @_reducer, {}
    data = @secondForm.serializeArray().reduce @_reducer, data
    $.post('/leads', lead: data)

  _reducer: (result, item) ->
    result[item.name] = item.value
    result

  _validateFirstScreen: ->
    if @firstForm.get(0).reportValidity
      @firstForm.get(0).reportValidity()
    @firstForm.get(0).checkValidity()

  _validateSecondScreen: ->
    if @secondForm.get(0).reportValidity
      @secondForm.get(0).reportValidity()
    @secondForm.get(0).checkValidity()

  _bind_inputs: ->
    @$modal.find('.js-not-interesting').on 'change', =>
      @$modal.find('.js-phone-number').attr('required', false)
      @canClose = true
      @close()

    @$modal.find('.js-interesting').on 'change', =>
      @$modal.find('.js-phone-number').attr('required', true).show()

    @$modal.find('input[name="phone_number"]').on 'keyup change', (event) =>
      if $(event.target).val() == ""
        @canClose = false
        @$modal.find('.js-close').hide()
      else
        @canClose = true
        @$modal.find('.js-close').show()

  _bind_buttons: ->
    @$modal.find('.radio-group .btn').on 'click', ->
      $(this).parent().find('.btn').removeClass('active')
      $(this).addClass('active')

    @$modal.find('.js-close').on 'click', =>
      @close()

    $('.js-prev-screen').on 'click', =>
      @firstForm.show()
      @secondForm.hide()
      @$modal.find('.js-prev-screen').hide()
      @$modal.find('.js-next-screen').show()

    $('.js-next-screen').on 'click', =>
      if @_validateFirstScreen()
        @firstForm.hide()
        @secondForm.show()
        @$modal.find('.js-prev-screen').show()
        @$modal.find('.js-next-screen').hide()
