class @RuleModal extends Modal
  newConditionTemplate: ->
    $('script#new-condition').html()

  constructor: (@$modal, @options={}) ->
    @_bindInteractions()
    super

  open: ->
    @_renderContent()
    super

  _bindInteractions: ->
    @_bindSubmit()
    @_bindAddCondition()
    @_bindRemoveCondition()

  _renderContent: ->
    ruleModal = this

    @$modal.find('.condition-block:not(".no-condition-message")').each ->
      $condition = $(this)
      ruleModal._renderCondition($condition)

    @$modal.on 'change', '.condition-segment, .condition-operand', ->
      $condition = $(this).parents('.condition-block:first')
      ruleModal._renderCondition($condition)

    @_toggleNewConditionMessage()

  _renderCondition: ($condition) ->
    @_renderOperand($condition)
    @_renderValue($condition)

  _renderOperand: ($condition) ->
    segment = $condition.find('select.condition-segment').val()
    operandHTML = @filteredOperands(segment)
    $operand = $condition.find('select.condition-operand')

    previousValue = $operand.val()
    selectedOption = operandHTML.filter -> @value == previousValue

    if selectedOption[0]
      selectedValue = selectedOption[0].value
    else
      selectedValue = operandHTML[0].value

    $operand.html(operandHTML)
            .val(selectedValue)

  _renderValue: ($condition) ->
    $condition.find('.choice-wrapper').hide()        # hide the selections by default
    $condition.find('.value').prop('disabled', true) # disable the values by default
    
    segmentValue = $condition.find('select.condition-segment').val()

    if segmentValue == 'CountryCondition'
      $condition.find('.country-choice')
                .show()
                .find('.value')
                .prop('disabled', false)
    else if segmentValue == 'DeviceCondition'
      $condition.find('.device-choice')
                .show()
                .find('.value')
                .prop('disabled', false)
    else if segmentValue == 'UrlCondition'
      $condition.find('.url-choice')
                .show()
                .find('.value')
                .prop('disabled', false)
    else if segmentValue == 'DateCondition'
      $condition.find('.date-choice')
                .show()
                .find('.value')
                .hide()

      operandValue = $condition.find('select.condition-operand').val()

      datesToShow = @_dateClasses(operandValue)
      $condition.find(datesToShow)
                .prop('disabled', false)
                .show()

      if datesToShow.indexOf(',') == -1
        $condition.find('.and-interjection').remove()
      else
        $condition.find('.start_date').after('<span class="and-interjection">and</span>') unless $condition.find('.and-interjection').length

      rawStartDate = $condition.find('.start_date').val()
      rawEndDate = $condition.find('.end_date').val()

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

  _dateClasses: (operand) ->
    if operand == 'is_before'
      '.end_date.value'
    else if operand == 'is_after'
      '.start_date.value'
    else if operand == 'is_between'
      '.start_date.value, .end_date.value'

  filteredOperands: (segment) ->
    conditionTemplate = @newConditionTemplate()
    validOperands = @_validOperands(segment)

    $(conditionTemplate).find('.condition-operand option')
                        .filter ->
                          $.inArray(@value, validOperands) != -1

  _validOperands: (segment) -> @_operandMapping[segment]

  _operandMapping:
    'CountryCondition': ['is', 'is_not']
    'DeviceCondition': ['is', 'is_not']
    'DateCondition': ['is_before', 'is_after', 'is_between']
    'UrlCondition': ['includes', 'excludes']

  _renderAlert: (content) ->
    template = Handlebars.compile($('script#alert-template').html())
    alert = template({type: 'error', content: content})
    @$modal.find('.modal-block').prepend(alert)

  _removeAlert: ->
    @$modal.find('.alert').remove()

  _bindSubmit: ->
    modal = this

    @$modal.find('form').on 'submit', (event) ->
      event.preventDefault()
      modal._removeAlert()

      $.ajax
        dataType: 'json'
        url: @action
        type: @method
        data: $(this).serialize()
        success: (data, status, xhr) ->
          modal.options.successCallback.call(data) if modal.options.successCallback
          modal.close()
        error: (xhr, status, error) ->
          console.log "Something went wrong: #{error}"

          content = ''

          for key in Object.keys(xhr.responseJSON)
            content += "#{key} #{xhr.responseJSON[key].join()}"
            content += "<br />"

          modal._renderAlert(content)

  _bindAddCondition: ->
    @$modal.on 'click', '.condition-add', (event) =>
      event.preventDefault()

      @_addCondition()
      @_toggleNewConditionMessage()

  _bindRemoveCondition: ->
    ruleModal = this

    @$modal.on 'click', '.condition-remove', (event) ->
      event.preventDefault()

      $condition = $(this).parents('.condition-block:first')
      ruleModal._removeCondition($condition)
      ruleModal._toggleNewConditionMessage()

  _addCondition: ->
    nextIndex = @$modal.find('.condition-block').length
    templateHTML = @newConditionTemplate()
    $condition = $(templateHTML)

    # update the names on the elements to be submitted properly
    $condition.find('[name="segment"]')
              .attr('name', "rule[conditions_attributes][#{nextIndex}][segment]")
    $condition.find('[name="operand"]')
              .attr('name', "rule[conditions_attributes][#{nextIndex}][operand]")
    $condition.find('[name="value"]')
              .attr('name', "rule[conditions_attributes][#{nextIndex}][value]")
    $condition.find('input.start_date')
              .attr('name', "rule[conditions_attributes][#{nextIndex}][value][start_date]")
    $condition.find('input.end_date')
              .attr('name', "rule[conditions_attributes][#{nextIndex}][value][end_date]")
    $condition.find('.choice-wrapper').hide()

    @_renderCondition($condition)
    @$modal.find('.conditions-wrapper').append($condition.html())

  _removeCondition: ($condition) ->
    $condition.find('.destroy').val(true)
    $condition.hide()

  _toggleNewConditionMessage: ->
    if @$modal.find('.condition-block:visible:not(".no-condition-message")').length == 0
      @$modal.find('.no-condition-message').show()
    else
      @$modal.find('.no-condition-message').hide()
