class @RuleModal extends Modal

  modalName: 'rules'
  ruleModalTemplate: -> $('script#rule-modal').html()
  conditionTemplate: -> $('script#condition-partial').html()

  constructor: (@options={}) ->
    @ruleData = @addMetadata(@options.ruleData)
    @$modal = @buildModal(@ruleData)

  buildModal: (ruleData) ->
    Handlebars.registerPartial("condition", @conditionTemplate())
    template = Handlebars.compile(@ruleModalTemplate())
    $(template(ruleData))

  buildCondition: (conditionData) ->
    template = Handlebars.compile(@conditionTemplate())
    $condition = $(template(conditionData))
    @_updateConditionMarkup($condition, conditionData)
    $condition

  addMetadata: (baseRuleData) ->
    completeData = $.extend {}, baseRuleData
    completeData.conditions ||= []

    for condition, index in completeData.conditions
      condition.index = index
      condition.is_between = true if condition.operand == 'between'

    completeData

  open: ->
    @_renderContent()
    @_bindInteractions()
    super

  close: ->
    @options.close() if @options.close
    super

  _bindInteractions: ->
    @_bindSubmit()
    @_bindAddCondition()
    @_bindRemoveCondition()

  _renderContent: ->
    $('body').append(@$modal)

    ruleModal = this

    # render all of the conditions
    for conditionData in @ruleData.conditions
      $condition = ruleModal.buildCondition(conditionData)
      ruleModal._addCondition($condition)

    @_toggleNewConditionMessage()

    @$modal.on 'change', '.rule_conditions_segment, .rule_conditions_operand', ->
      $this = $(this)
      $condition = $this.parents('.condition-block:first')

      # reset the value if the segment changes
      if $this.hasClass('rule_conditions_segment')
        value = null
      else
        value = $condition.find('.value:visible').val()

      conditionData =
        id: $condition.find('.condition-id').val()
        index: $condition.data('condition-index')
        segment: $condition.find('.condition-segment').val()
        operand: $condition.find('.condition-operand').val()
        value: value

      $updatedCondition = ruleModal.buildCondition(conditionData)

      # replace the markup of the condition based on new data
      $condition.html($updatedCondition.html())

  _updateConditionMarkup: ($condition, conditionData) ->
    @_renderOperands($condition, conditionData)
    @_renderValue($condition, conditionData)

  _renderOperands: ($condition, conditionData) ->
    validOperands = @filteredOperands(conditionData.segment)

    $condition.find('select.condition-operand option')
              # filter and remove all invalid operands for this condition
              .filter (index, option) ->
                $option = $(option)
                $.inArray($option.val(), validOperands) == -1
              .remove()

  _renderValue: ($condition, conditionData) ->
    $condition.find('.choice-wrapper').hide()        # hide the selections by default
    $condition.find('.value').prop('disabled', true) # disable the values by default


    if conditionData.segment == 'DateCondition'
      datesToShow = @_dateClasses(conditionData.operand)
      $condition.find('.date-choice')
                .show()
                .find('.value')
                .hide()

      $condition.find(datesToShow)
                .prop('disabled', false)
                .show()

      @_formatDates($condition, conditionData)
    else
      classToEnable = @_segmentToClassMapping[conditionData.segment]
      $condition.find(classToEnable)
                .show()
                .find('.value')
                .prop('disabled', false)

  _formatDates: ($condition, conditionData) ->
    conditionData.value ||= {}
    datesToShow = @_dateClasses(conditionData.operand)

    if datesToShow.indexOf(',') == -1
      $condition.find('.and-interjection').remove()
    else
      $condition.find('.start_date').after('<span class="and-interjection">and</span>') unless $condition.find('.and-interjection').length

    rawStartDate = conditionData.value.start_date
    rawEndDate = conditionData.value.end_date

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
    switch operand
      when 'before' then '.end_date.value'
      when 'after' then '.start_date.value'
      when 'between' then '.start_date.value, .end_date.value'
      else '.start_date.value'

  filteredOperands: (segment) ->
    @_validOperands(segment)

  _validOperands: (segment) -> @_operandMapping[segment]

  _operandMapping:
    'DeviceCondition': ['is', 'is_not']
    'DateCondition': ['is', 'is_not', 'before', 'after', 'between']
    'UrlCondition': ['is', 'is_not', 'includes', 'does_not_include']

  _segmentToClassMapping:
    'DeviceCondition': '.device-choice'
    'DateCondition': '.date-choice'
    'UrlCondition': '.url-choice'

  _renderAlert: (content) ->
    template = Handlebars.compile($('script#alert-template').html())
    alert = template({type: 'error', content: content})
    @$modal.find('.modal-block').prepend(alert)

  _removeAlerts: ->
    @$modal.find('.alert').remove()

  _bindSubmit: ->
    modal = this

    @$modal.find('form').on 'submit', (event) ->
      event.preventDefault()
      modal._removeAlerts()

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

          if xhr.responseJSON
            for key in Object.keys(xhr.responseJSON)
              content += "#{key} #{xhr.responseJSON[key].join()}"
              content += "<br />"
          else
            content = error

          modal._renderAlert(content)

  _bindAddCondition: ->
    @$modal.on 'click', '.condition-add', (event) =>
      event.preventDefault()

      nextIndex = @$modal.find('.condition-block:not(".no-condition-message")').length
      # default condition data
      conditionData =
        index: nextIndex
        segment: 'DeviceCondition'
        operand: 'is'

      $condition = @buildCondition(conditionData)

      @_addCondition($condition)
      @_toggleNewConditionMessage()

  _bindRemoveCondition: ->
    ruleModal = this

    @$modal.on 'click', '.condition-remove', (event) ->
      event.preventDefault()

      $condition = $(this).parents('.condition-block:first')
      ruleModal._removeCondition($condition)
      ruleModal._toggleNewConditionMessage()

  # renders a condition to the page
  _addCondition: ($condition) ->
    @$modal.find('.conditions-wrapper').append($condition.prop('outerHTML'))

  _removeCondition: ($condition) ->
    # set the hidden destroy field to true for Rails to pick up
    $condition.find('.destroy').val(true)
    $condition.hide()

  _toggleNewConditionMessage: ->
    if @$modal.find('.condition-block:visible:not(".no-condition-message")').length == 0
      @$modal.find('.no-condition-message').show()
    else
      @$modal.find('.no-condition-message').hide()
