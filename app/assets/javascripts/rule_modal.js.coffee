class @RuleModal
  newConditionTemplate: ->
    $('script#new-condition').html()

  constructor: (@$modal) ->
    @_bindInteractions()

  open: ->
    @_renderContent()
    @$modal.addClass('show-modal')

  close: ->
    @$modal.removeClass('show-modal')
           .off() # unbind all modal events

  _bindInteractions: ->
    @_bindCloseEvents(@close)
    @_bindSubmit()
    @_bindAddCondition()
    @_bindRemoveCondition()

  _renderContent: ->
    ruleModal = this

    @$modal.find('.condition').each ->
      $condition = $(this)
      ruleModal._renderOperand($condition)
      ruleModal._renderValue($condition)

    @$modal.on 'change', '.form-control', ->
      $condition = $(this).parents('.condition:first')
      ruleModal._renderOperand($condition)
      ruleModal._renderValue($condition)

  _renderOperand: ($condition) ->
    segment = $condition.find('.rule_conditions_segment select').val()
    operands = @filteredOperands(segment)
    $operand = $condition.find('.rule_conditions_operand')

    previousValue = $operand.find('select :selected').val()
    selectedOption = operands.filter(->
      @value == previousValue
    )

    if selectedOption[0]
      selectedValue = selectedOption[0].value
    else
      selectedValue = operands[0].value

    $operand.find('select').html(operands)
                           .val(selectedValue)

  _renderValue: ($condition) ->
      $condition.find('.value').hide() # hide the values by default
      $value = $condition.find('.rule_conditions_value')
      segmentValue = $condition.find('.rule_conditions_segment .select').val()
      valueId = $value.find('input').attr('id')
      valueName = $value.find('input').attr('name')

      if segmentValue == 'CountryCondition'
        $condition.find('.country')
                  .prop('disabled', false)
                  .show()
      else if segmentValue == 'DeviceCondition'
        $condition.find('.device')
                  .prop('disabled', false)
                  .show()
      else if segmentValue == 'UrlCondition'
        $condition.find('.url')
                  .prop('disabled', false)
                  .show()
      else if segmentValue == 'DateCondition'
        operandValue = $condition.find('.rule_conditions_operand .select').val()

        elementsToShow = @_valueClass(segmentValue, operandValue)
        $condition.find(elementsToShow)
                  .prop('disabled', false)
                  .show()

        rawStartDate = $condition.find('.start_date').attr('value')
        rawEndDate = $condition.find('.end_date').attr('value')

        # date parsing requires slashes
        rawStartDate = rawStartDate.replace(/\-/g, '/') if rawStartDate
        rawEndDate = rawEndDate.replace(/\-/g, '/') if rawEndDate

        if rawStartDate
          startDate = new Date(rawStartDate)
          paddedStartMonth = $.zeropad startDate.getMonth() + 1
          paddedStartDate = $.zeropad startDate.getDate()
          startDateString = "#{startDate.getFullYear()}-#{paddedStartMonth}-#{paddedStartDate}"
          $condition.find('.start_date').val(startDateString)

        if rawEndDate
          endDate = new Date(rawEndDate)
          paddedEndMonth = $.zeropad endDate.getMonth() + 1
          paddedEndDate = $.zeropad endDate.getDate()
          endDateString = "#{endDate.getFullYear()}-#{paddedEndMonth}-#{paddedEndDate}"
          $condition.find('.end_date').val(endDateString)

  _valueClass: (segment, operand) ->
    if segment == 'UrlCondition'
      '.url.value'
    else if segment == 'DateCondition'
      if operand == 'is_before'
        '.end_date.value'
      else if operand == 'is_after'
        '.start_date.value'
      else if operand == 'is_between'
        '.start_date.value, .end_date.value'

  filteredOperands: (segment) ->
    conditionTemplate = @newConditionTemplate()
    validOperands = @_validOperands(segment)

    $(conditionTemplate).find('#operand option')
                        .filter ->
                          $.inArray(@value, validOperands) != -1

  _validOperands: (segment) -> @_operandMapping[segment]

  _operandMapping:
    'CountryCondition': ['is', 'is_not']
    'DeviceCondition': ['is', 'is_not']
    'DateCondition': ['is_before', 'is_after', 'is_between']
    'UrlCondition': ['includes', 'excludes']

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
          console.log "Something went wrong: #{error}"

  _bindAddCondition: ->
    @$modal.on 'click', '.add', (event) =>
      @_addCondition()
      @_toggleNoConditionMessage()

  _bindRemoveCondition: ->
    ruleModal = this

    @$modal.on 'click', '.remove', (event) ->
      $condition = $(this).parents('.condition:first')
      ruleModal._removeCondition($condition)
      ruleModal._toggleNoConditionMessage()

  _addCondition: ->
    nextIndex = @$modal.find('.conditions').length
    templateHTML = @newConditionTemplate()
    $template = $(templateHTML)

    # update the names on the elements to be submitted properly
    $template.find('[name="segment"]')
             .attr('name', "rule[conditions_attributes][#{nextIndex}][segment]")
    $template.find('[name="operand"]')
             .attr('name', "rule[conditions_attributes][#{nextIndex}][operand]")
    $template.find('[name="value"]')
             .attr('name', "rule[conditions_attributes][#{nextIndex}][value]")

    @_renderOperand($template)
    @$modal.find('.conditions').append($template.html())

  _removeCondition: ($condition) ->
    $condition.find('.rule_conditions__destroy input').val(true)
    $condition.hide()

  _toggleNoConditionMessage: ->
    if @$modal.find('.condition:visible').length == 0
      $('span.bg-warning').removeClass('hidden')
    else
      $('span.bg-warning').addClass('hidden')

  _bindCloseEvents: (callback) ->
    @_bindEscape(callback)
    @_bindClickOnClose(callback)
    @_bindClickOutsideTarget(callback)

  _bindEscape: (callback) ->
    $(document).on 'keyup', (event) =>
      callback.call(this) if event.keyCode == 27

  _bindClickOnClose: (callback) ->
    @$modal.find('a.cancel').on 'click', (event) =>
      callback.call(this)

  _bindClickOutsideTarget: (callback) ->
    @$modal.on 'click', (event) =>
      callback.call(this) if $(event.target).hasClass('modal-wrapper')
