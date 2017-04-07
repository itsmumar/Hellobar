
class @LeadDataModal extends Modal
  canClose: true
  modalName: 'lead-data'

  constructor: (@options = {}) ->
    # *gon* variables are defined here: app/controllers/concerns/gon_variables.rb
    industries = gon.lead_data_modal.industries.map (industry) => {name: industry, value: industry.toLowerCase()}
    roles = gon.lead_data_modal.job_roles.map (role) => {name: role, value: role.toLowerCase()}
    companySizes = gon.lead_data_modal.company_sizes.map (size) => {name: size, value: size.toLowerCase()}
    trafficItems = gon.lead_data_modal.traffic_items.map (size) => {name: size, value: size.toLowerCase()}
    challenges = gon.lead_data_modal.challenges

    @$modal = @_render('lead-data-template', {industries, roles, companySizes, trafficItems, challenges, currentUser})
    @$modal.appendTo($("body"))
    @$firstForm = @$modal.find('form.screen-1')
    @$secondForm = @$modal.find('form.screen-2')
    @_bindButtons()
    @_bindInputs()
    super(@$modal)

  close: ->
    return unless @_validateSecondScreen() && @canClose
    @_saveData()
    super

  _saveData: ->
    data = @$firstForm.serializeArray().reduce @_reducer, {}
    data = @$secondForm.serializeArray().reduce @_reducer, data
    $.post('/leads', lead: data)

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
      @$modal.find('.js-next-screen').show()

    $('.js-next-screen').on 'click', =>
      if @_validateFirstScreen()
        @$firstForm.hide()
        @$secondForm.show()
        @$modal.find('.js-prev-screen').show()
        @$modal.find('.js-next-screen').hide()
