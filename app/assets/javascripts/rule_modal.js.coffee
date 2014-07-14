class @RuleModal
  constructor: (@$modal) ->
    @_bindEscape(@close)
    @_bindClickOnClose(@close)

  open: ->
    @_renderContent()
    @_bindSubmit()
    @_bindAddCondition()
    @_bindRemoveCondition()
    @$modal.addClass('show-modal')

  close: ->
    @$modal.removeClass('show-modal')
    @$modal.off() # unbind all modal events

  valueClass: (segment, operand) ->
    if segment == 'UrlCondition'
      '.url.value'
    else if segment == 'DateCondition'
      if operand == 'is_before'
        '.end_date.value'
      else if operand == 'is_after'
        '.start_date.value'
      else if operand == 'is_between'
        '.start_date.value, .end_date.value'

  _renderContent: ->
    @$modal.find('.condition').each (index, condition) =>
      $condition = $(condition)
      # TODO: DONT HIDE THE SEGMENT OR OPERAND
      $condition.find('.value').hide()

      $value = $condition.find('.rule_conditions_value')

      segmentValue = $condition.find('.rule_conditions_segment .select').val()
      valueId = $value.find('input').attr('id')
      valueName = $value.find('input').attr('name')

      if $.inArray(segmentValue, ['CountryCondition', 'DeviceSegment']) == 1
        $value.replaceWith('<span>We dont support this yet</span>')
        # show the condition
        # change the value input to a dropdown
        # where will we store the Country and Device options
      else if segmentValue == 'UrlCondition'
        $condition.find('.url')
                  .prop('disabled', false)
                  .show()
        # show the condition
      else if segmentValue == 'DateCondition'
        operandValue = $condition.find('.rule_conditions_operand .select').val()

        elementsToShow = @valueClass(segmentValue, operandValue)
        $condition.find(elementsToShow)
                  .prop('disabled', false)
                  .show()

        rawStartDate = $condition.find('.start_date').attr('value')
        rawEndDate = $condition.find('.end_date').attr('value')

        if rawStartDate
          startDate = new Date(rawStartDate)
          paddedStartMonth = "0#{startDate.getMonth()+1}".slice(-2)
          paddedStartDate = "0#{startDate.getDate()}".slice(-2)
          startDateString = "#{startDate.getFullYear()}-#{paddedStartMonth}-#{paddedStartDate}"
          $condition.find('.start_date').val(startDateString)

        if rawEndDate
          endDate = new Date(rawEndDate)
          paddedEndMonth = "0#{endDate.getMonth()+1}".slice(-2)
          paddedEndDate = "0#{endDate.getDate()}".slice(-2)
          endDateString = "#{endDate.getFullYear()}-#{paddedEndMonth}-#{paddedEndDate}"
          $condition.find('.end_date').val(endDateString)

  _bindSubmit: ->
    modal = this

    @$modal.find('form').on 'submit', (event) ->
      event.preventDefault()

      $.ajax
        dataType: 'json'
        url: @action
        type: @method
        data: $(this).serialize()
        success: (data, status, xhr) ->
          modal.close()
        error: (xhr, status, error) ->
          alert 'Something went wrong: ' + error

  _bindAddCondition: ->
    @$modal.on 'click', '.add', (event) =>
      template = $('script#new-condition').html()
      @$modal.find('.conditions').append(template)

  _bindRemoveCondition: ->
    @$modal.on 'click', '.remove', (event) ->
      $condition = $(this).parents('.condition:first')
      $condition.find('.rule_conditions__destroy input').val(true)
      $condition.hide()

  _bindEscape: (callback) ->
    $(document).on 'keyup', (event) =>
      callback.call(@) if event.keyCode == 27

  _bindOnClickOutsideTarget: (callback) ->
    #

  _bindClickOnClose: (callback) ->
    @$modal.find('a.cancel').on 'click', (event) =>
      callback.call(@)

  # isConflicted
  #   -

  # renderConflictMessage
  #   - adds a display class to the dialog box

  # <select class="select optional form-control" id="rule_conditions_attributes_0_segment" name="rule[conditions_attributes][0][segment]"><option value=""></option>
  #   <option value="country">country</option>
  #   <option value="device">device</option>
  #   <option value="date">date</option>
  #   <option value="url">url</option>
  # </select>
