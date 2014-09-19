class @RuleModal extends Modal

  modalName: 'rules'

  newConditionTemplate: ->
    $('script#condition-partial').html()

  constructor: (@options={}) ->
    source = $('script#rule-modal').html()
    template = Handlebars.compile(source)
    Handlebars.registerPartial("condition", @newConditionTemplate())
    @ruleData = @options.ruleData
    @$modal = $(template(@ruleData))

  open: ->
    @_renderContent()
    @_bindInteractions()
    super

  close: ->
    @options.close() if @options.close
    @$modal.remove()

  _bindInteractions: ->
    @_bindSubmit()
    @_bindAddCondition()
    @_bindRemoveCondition()

  _renderContent: ->
    $('body').append(@$modal)

    ruleModal = this
    @ruleData.conditions ||= []

    for conditionData in @ruleData.conditions
      $condition = @$modal.find(".condition-id[value=#{conditionData.id}]").parents('.condition-block')
      ruleModal._renderCondition($condition, conditionData)

    @$modal.on 'change', '.rule_conditions_segment, .rule_conditions_operand', ->
      $this = $(this)
      $condition = $this.parents('.condition-block:first')

      if $this.hasClass('rule_conditions_segment')
        value = null
      else
        value = $condition.find('.value:visible').val()
      # reset the value if the segment changed

      template = Handlebars.compile(ruleModal.newConditionTemplate())

      conditionData =
        id: $condition.find('.condition-id').val()
        index: $condition.data('condition-index')
        segment: $condition.find('.condition-segment').val()
        operand: $condition.find('.condition-operand').val()
        value: value

      $updatedCondition = $(template(conditionData))
      ruleModal._renderCondition($updatedCondition, conditionData)

      $condition.html($updatedCondition.html())

    @_toggleNewConditionMessage()

  # SIDE EFFECT: this method mutates $condition
  _renderCondition: ($condition, conditionData) ->
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

    # TODO: can we just have a function that returns the proper
    # class choice based on the segment and
    # find/show/find/disable all at once?
    switch conditionData.segment
      when 'DeviceCondition'
        $condition.find('.device-choice')
                  .show()
                  .find('.value')
                  .prop('disabled', false)
      when 'UrlCondition'
        $condition.find('.url-choice')
                  .show()
                  .find('.value')
                  .prop('disabled', false)
      when 'DateCondition'
        $condition.find('.date-choice')
                  .show()
                  .find('.value')
                  .hide()

        datesToShow = @_dateClasses(conditionData.operand)
        $condition.find(datesToShow)
                  .prop('disabled', false)
                  .show()

        @_formatDates($condition, conditionData)

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
      when 'is_before' then '.end_date.value'
      when 'is_after' then '.start_date.value'
      when 'is_between' then '.start_date.value, .end_date.value'
      else '.start_date.value'

  filteredOperands: (segment) ->
    @_validOperands(segment)

  _validOperands: (segment) -> @_operandMapping[segment]

  _operandMapping:
    'DeviceCondition': ['is', 'is_not']
    'DateCondition': ['is_before', 'is_after', 'is_between']
    'UrlCondition': ['includes', 'does_not_include']

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
    nextIndex = @$modal.find('.condition-block:not(".no-condition-message")').length
    template = Handlebars.compile(@newConditionTemplate())
    # default condition data
    conditionData =
      index: nextIndex
      segment: 'DeviceCondition'
      operand: 'is'
    $condition = $(template(conditionData))

    @_renderCondition($condition, conditionData)
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
