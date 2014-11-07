class @RuleModal extends Modal

  modalName: 'rules'
  ruleModalTemplate: -> $('script#rule-modal').html()
  conditionTemplate: -> $('script#condition-partial').html()

  constructor: (@options={}) ->
    @ruleData = @options.ruleData
    @ruleData.conditions ||= []
    @$modal = @buildModal(@ruleData)

  buildModal: (ruleData) ->
    Handlebars.registerPartial("condition", @conditionTemplate())
    template = Handlebars.compile(@ruleModalTemplate())
    $(template(ruleData))

  buildCondition: (conditionData, index) ->
    conditionData.index ||= index
    conditionData.is_between = true if conditionData.operand == 'between'

    template = Handlebars.compile(@conditionTemplate())
    $condition = $(template(conditionData))
    @_updateConditionMarkup($condition, conditionData)
    $condition

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
    @_bindUrlActions()

  _renderContent: ->
    $('body').append(@$modal)

    ruleModal = this

    console.log 'k', @ruleData

    # render all of the conditions
    for conditionData, index in @ruleData.conditions
      $condition = ruleModal.buildCondition(conditionData, index)
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

      $updatedCondition = ruleModal.buildCondition(conditionData, conditionData.index)

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

    classToEnable = @_segmentToClassMapping[conditionData.segment]
    $condition.find(classToEnable)
              .show()
              .find('.value')
              .prop('disabled', false)

  filteredOperands: (segment) ->
    @_validOperands(segment)

  _validOperands: (segment) -> @_operandMapping[segment]

  _operandMapping:
    'DeviceCondition': ['is', 'is_not']
    'DateCondition': ['is', 'is_not', 'before', 'after', 'between']
    'NumberOfVisitsCondition': ['is', 'is_not', 'less_than', 'greater_than', 'between']
    'ReferrerCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'SearchTermCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'UrlCondition': ['is', 'is_not', 'includes', 'does_not_include']

  _segmentToClassMapping:
    'DeviceCondition': '.device-choice'
    'DateCondition': '.date-choice'
    'NumberOfVisitsCondition': '.number-of-visits-choice'
    'ReferrerCondition': '.referrer-choice'
    'SearchTermCondition': '.search-term-choice'
    'UrlCondition': '.url-choice'

  _bindSubmit: ->
    modal = this

    @$modal.find('form').on 'submit', (event) ->
      event.preventDefault()
      modal._clearErrors()
  
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

          content = []

          if xhr.responseJSON
            for key in Object.keys(xhr.responseJSON)
              content.push("#{key} #{xhr.responseJSON[key].join()}")
          else
            content.push(error)

          modal._displayErrors(content)

  _bindAddCondition: ->
    @$modal.on 'click', '.condition-add', (event) =>
      event.preventDefault()

      nextIndex = @$modal.find('.condition-block:not(".no-condition-message")').length
      # default condition data
      conditionData =
        index: nextIndex
        segment: 'DeviceCondition'
        operand: 'is'

      $condition = @buildCondition(conditionData, nextIndex)

      @_addCondition($condition)
      @_toggleNewConditionMessage()

  _bindRemoveCondition: ->
    ruleModal = this

    @$modal.on 'click', '.condition-remove', (event) ->
      event.preventDefault()

      $condition = $(this).parents('.condition-block:first')
      ruleModal._removeCondition($condition)
      ruleModal._toggleNewConditionMessage()

  #-----------  Render a Condition to the Page  -----------#

  _addCondition: ($condition) ->
    @$modal.find('.conditions-wrapper').append($condition.prop('outerHTML'))

  _removeCondition: ($condition) ->
    # if persisted, set the hidden destroy field to true for Rails to pick up
    if $condition.find('.condition-id').length
      $condition.find('.destroy').val(true)
      $condition.hide()
    else # just remove from DOM
      $condition.remove()

  _toggleNewConditionMessage: ->
    if @$modal.find('.condition-block:visible:not(".no-condition-message")').length == 0
      @$modal.find('.no-condition-message').show()
    else
      @$modal.find('.no-condition-message').hide()

  #-----------  Adding / Subtracting URLs  -----------#

  _bindUrlActions: ->
    @$modal.on 'click', '.url-add', (event) ->
      event.preventDefault()

      $inputWrapper = $(this).closest('.url-choice')
      $inputBlock   = $(this).closest('.url-input-wrapper')

      $inputBlock.clone()
                 .css({opacity: 0, maxHeight: 0})
                 .appendTo($inputWrapper)
                 .animate({opacity: 1, maxHeight: '3em'}, 200)
                 .find('input').val(null)

    @$modal.on 'click', '.url-remove', (event) ->
      event.preventDefault()

      $(this).closest('.url-input-wrapper')
             .animate({opacity: 0, maxHeight: 0}, 200, -> $(@).remove())