class @RuleModal
  constructor: (@$modal) ->
    @_bindEscape(@close)

  open: ->
    @_renderContent()
    @$modal.addClass('show-modal')

  close: ->
    @$modal.removeClass('show-modal')
    @$modal.off() # unbind all modal events

  _renderContent: ->
    @$modal.find('.condition').each (index, condition) ->
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
        # TODO: GET RID OF THE UNNECESSARY OPERANDS FOR DATE!!!
        operandValue = $condition.find('.rule_conditions_operand .select').val()

        if operandValue == 'is_after'
          rawStartDate = $condition.find('.start_date')
                                   .prop('disabled', false)
                                   .show()
                                   .attr('value')

          # TODO: PULL INTO DATE PARSING / DISPLAYING UTILITY CLASS
          date = new Date(rawStartDate)
          paddedMonth = "0#{date.getMonth()+1}".slice(-2)
          paddedDate = "0#{date.getDate()}".slice(-2)

          dateString = "#{date.getFullYear()}-#{paddedMonth}-#{paddedDate}"
          # /TODO

          $condition.find('.start_date').val(dateString)
        else if operandValue == 'is_before'
          rawEndDate = $condition.find('.end_date')
                                   .prop('disabled', false)
                                   .show()
                                   .attr('value')

          date = new Date(rawEndDate)
          paddedMonth = "0#{date.getMonth()+1}".slice(-2)
          paddedDate = "0#{date.getDate()}".slice(-2)

          dateString = "#{date.getFullYear()}-#{paddedMonth}-#{paddedDate}"

          $condition.find('.end_date').val(dateString)
        else if operandValue == 'is_between'
          $condition.find('.start_date, .end_date')
                    .prop('disabled', false)
                    .show()

          rawStartDate = $condition.find('.start_date').attr('value')
          rawEndDate = $condition.find('.end_date').attr('value')

          startDate = new Date(rawStartDate)
          paddedStartMonth = "0#{startDate.getMonth()+1}".slice(-2)
          paddedStartDate = "0#{startDate.getDate()}".slice(-2)
          startDateString = "#{startDate.getFullYear()}-#{paddedStartMonth}-#{paddedStartDate}"

          endDate = new Date(rawEndDate)
          paddedEndMonth = "0#{endDate.getMonth()+1}".slice(-2)
          paddedEndDate = "0#{endDate.getDate()}".slice(-2)
          endDateString = "#{endDate.getFullYear()}-#{paddedEndMonth}-#{paddedEndDate}"

          $condition.find('.start_date').val(startDateString)
          $condition.find('.end_date').val(endDateString)

  _bindEscape: (callback) ->
    $(document).on 'keyup', (event) =>
      callback.call(@) if event.keyCode == 27

  _bindOnClickOutsideTarget: (callback) ->
    #

  _bindClickOnClose: (callback) ->

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
