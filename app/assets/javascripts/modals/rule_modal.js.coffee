class @RuleModal extends Modal

  modalName: 'rules'
  ruleModalTemplate: -> $('script#rule-modal').html()
  conditionTemplate: -> $('script#condition-partial').html()

  constructor: (@options={}) ->
    @ruleData = @options.ruleData
    @site = @options.site
    @ruleData.conditions ||= []
    @$modal = @buildModal(@ruleData)

  buildModal: (ruleData) ->
    Handlebars.registerPartial("condition", @conditionTemplate())
    template = Handlebars.compile(@ruleModalTemplate())
    $(template(ruleData))

  buildCondition: (conditionData, index) ->
    conditionData.index ||= index
    conditionData.is_between = true if conditionData.operand == 'between'
    conditionData.canUseAdvancedLocation = @site.capabilities.precise_geolocation_targeting
    template = Handlebars.compile(@conditionTemplate())
    $condition = $(template(conditionData))
    @_updateConditionMarkup($condition, conditionData)
    $condition

  open: ->
    @_renderContent()
    @_bindInteractions()
    super

  # cancel and close are two fundamentally different concepts, and yet they've been forced into a single action :'(
  # rather than refactor modals entirely, passing in a flag of cancel vs. close allows for different behaviour
  close: (cancel = true) ->
    @options.close(cancel) if @options.close
    super

  _bindInteractions: ->
    @_bindSubmit()
    @_bindAddCondition()
    @_bindRemoveCondition()
    @_bindMultipleChoiceActions()
    @_bindSelectionChanges()

  _removeUrlCondition: ->
    urlCondition = @ruleData.conditions.find (condition) ->
      condition.segment == "UrlCondition"

    # delete the UrlCondition if the user isn't using it
    unless urlCondition
      this.$modal.find('select.condition-segment option[value="UrlCondition"]').remove()


  _renderContent: ->
    $('body').append(@$modal)

    ruleModal = this

    # render all of the conditions
    for conditionData, index in @ruleData.conditions
      $condition = ruleModal.buildCondition(conditionData, index)
      ruleModal._addCondition($condition)

    @_removeUrlCondition()

    @_toggleNewConditionMessage()

    @$modal.on 'change', '.rule_conditions_segment, .rule_conditions_data_type, .rule_conditions_operand', ->
      $this = $(this)
      $condition = $this.parents('.condition-block:first')
      segment = $condition.find('.condition-segment').val()

      # reset the value if the segment changes
      if $this.hasClass('rule_conditions_segment')
        value = null
      else if segment == "UrlCondition" || segment == "UrlPathCondition"
        value = $.map($condition.find('.value:visible'), (field, i) -> $(field).val())
      else
        value = $condition.find('.value:visible').val()

      conditionData =
        id: $condition.find('.condition-id').val()
        index: $condition.data('condition-index')
        segment: segment
        operand: $condition.find('.condition-operand').val()
        custom_segment: $condition.find('.custom-segment-name-input').val()
        data_type: $condition.find('.condition-data-type').val() || 'string'
        value: value

      $updatedCondition = ruleModal.buildCondition(conditionData, conditionData.index)

      # replace the markup of the condition based on new data
      $condition.html($updatedCondition.html())

  _updateConditionMarkup: ($condition, conditionData) ->
    @_renderDataTypes($condition, conditionData)
    @_renderOperands($condition, conditionData)
    @_renderValue($condition, conditionData)
    @_renderCustomSegment($condition, conditionData)

  _renderDataTypes: ($condition, conditionData) ->
    types = Object.keys(@_dataTypeOperandMapping)

    if conditionData.segment == 'CustomCondition'
      $condition.find('select.condition-data-type option')
                # filter and remove all invalid operands for this condition
                .filter (index, option) ->
                  $option = $(option)
                  $.inArray($option.val(), types) == -1
                .remove()
    else
      $condition.find('.rule_conditions_data_type').remove()

  _renderOperands: ($condition, conditionData) ->
    validOperands = @filteredOperands(conditionData.segment)
    if conditionData.segment == 'CustomCondition'
      validOperands = @_dataTypeOperandMapping[conditionData.data_type]
    else
      $condition.find('.custom-segment-text').remove()

    $condition.find('select.condition-operand option')
              # filter and remove all invalid operands for this condition
              .filter (index, option) ->
                $option = $(option)
                $.inArray($option.val(), validOperands) == -1
              .remove()

  _renderValue: ($condition, conditionData) ->
    $condition.find('.choice-wrapper').hide()        # hide the selections by default
    $condition.find('.rule_conditions_choices .value').prop('disabled', true) # disable the values by default

    classToEnable = @_segmentToClassMapping[conditionData.segment]

    if conditionData.segment == 'CustomCondition'
      classToEnable = @_dataTypeToClass[conditionData.data_type]

    # select the country because country_select is rendered on the server
    # we must select this manually with JS
    # country data should be initialized as array.
    if conditionData.segment == 'LocationCountryCondition'
      dataValue = (if typeof conditionData.value == "object" \
                      then conditionData.value \
                      else [conditionData.value]) || []
      for value, index in dataValue
        $($condition.find(classToEnable)
                    .find(".value > option[value=\"#{value}\"]")[index])
                    .attr('selected', 'selected')
    else if conditionData.segment == 'TimeCondition'
      # select the correct hour
      hourValue = conditionData.value?[0] || 0
      minuteValue = conditionData.value?[1] || 0
      timezoneValue = conditionData.value?[2] || window.siteTimezone || "visitor"

      $condition.find(classToEnable)
                .find(".value:eq(0) > option[value=\"#{hourValue}\"]")
                .attr('selected', 'selected')

      # select the correct minute
      $condition.find(classToEnable)
                .find(".value:eq(1) > option[value=\"#{minuteValue}\"]")
                .attr('selected', 'selected')

      $condition.find(classToEnable)
                .find(".value:eq(2) > option[value=\"#{timezoneValue}\"]")
                .attr('selected', 'selected')

    $condition.find(classToEnable)
              .show()
              .find('.value')
              .prop('disabled', false)

  _renderCustomSegment: ($condition, conditionData) ->
    if conditionData.segment != 'CustomCondition'
      $condition.find('.custom-segment-name')
                .hide()
                .find('.value')
                .prop('disabled', true)

  filteredOperands: (segment) ->
    @_validOperands(segment)

  _validOperands: (segment) -> @_operandMapping[segment]

  _operandMapping:
    'DateCondition': ['is', 'is_not', 'before', 'after', 'between']
    'DeviceCondition': ['is', 'is_not']
    'EveryXSession': ['every']
    'LastVisitCondition': ['is', 'is_not', 'less_than', 'greater_than', 'between']
    'LocationCityCondition': ['is', 'is_not']
    'LocationCountryCondition': ['is', 'is_not']
    'LocationRegionCondition': ['is', 'is_not']
    'NumberOfVisitsCondition': ['is', 'is_not', 'less_than', 'greater_than', 'between']
    'PreviousPageURL': ['includes', 'does_not_include']
    'ReferrerCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'ReferrerDomainCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'SearchTermCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'TimeCondition': ['before', 'after']
    'UTMCampaignCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'UTMContentCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'UTMMediumCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'UTMSourceCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'UTMTermCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'UrlCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'UrlPathCondition': ['is', 'is_not', 'includes', 'does_not_include']
    'UrlQuery': ['is', 'is_not', 'includes', 'does_not_include']

  _segmentToClassMapping:
    'DateCondition': '.date-choice'
    'DeviceCondition': '.device-choice'
    'EveryXSession': '.x-sessions'
    'LastVisitCondition': '.days-last-visit-choice'
    'LocationCityCondition': '.location-city-choice'
    'LocationCountryCondition': '.location-country-choice'
    'LocationRegionCondition': '.location-region-choice'
    'NumberOfVisitsCondition': '.number-of-visits-choice'
    'PreviousPageURL': '.previous-page-choice'
    'ReferrerCondition': '.referrer-choice'
    'ReferrerDomainCondition': '.referrer-domain-choice'
    'SearchTermCondition': '.search-term-choice'
    'TimeCondition': '.time-choice'
    'UTMCampaignCondition': '.utm-campaign-choice'
    'UTMContentCondition': '.utm-content-choice'
    'UTMMediumCondition': '.utm-medium-choice'
    'UTMSourceCondition': '.utm-source-choice'
    'UTMTermCondition': '.utm-term-choice'
    'UrlCondition': '.url-choice'
    'UrlPathCondition': '.url-choice'
    'UrlQuery': '.url-query'

  _dataTypeOperandMapping:
    'string': ['is', 'is_not', 'includes', 'does_not_include']
    'date': ['is', 'is_not', 'before', 'after', 'between']
    'number': ['is', 'is_not', 'less_than', 'greater_than']

  _dataTypeToClass:
    'date': '.date-choice'
    'string': '.string-choice'
    'number': '.number-of-visits-choice'

  _bindSubmit: ->
    @_unbindSubmit() # clear any existing event bindings to make sure we only have one at a time
    modal = this

    @$modal.find("a.submit").on 'click', (event) =>
      @_unbindSubmit()
      event.preventDefault()
      modal._clearErrors()

      $form = @$modal.find("form")
      $form.find("a.submit").addClass("cancel")
      window.form = $form

      $.ajax
        dataType: 'json'
        url: $form.attr("action")
        type: $form.attr("method")
        data: $form.serialize()
        success: (data, status, xhr) ->
          modal.options.successCallback.call(data) if modal.options.successCallback
          modal.close(false)
        error: (xhr, status, error) ->
          $form.find("a.submit").removeClass("cancel")
          console.log "Something went wrong: #{error}"

          content = []

          if xhr.responseJSON
            for key in Object.keys(xhr.responseJSON)
              content.push("#{key} #{xhr.responseJSON[key].join()}")
          else
            content.push(error)

          modal._displayErrors(content)
          modal._bindSubmit()

  _unbindSubmit: ->
    @$modal.find('a.submit').off('click')

  _bindAddCondition: ->
    @$modal.on 'click', '.condition-add', (event) =>
      event.preventDefault()

      nextIndex = @$modal.find('.condition-block:not(".no-condition-message")').length
      # default condition data
      conditionData =
        index: nextIndex
        segment: 'DeviceCondition'
        data_type: 'string'
        operand: 'is'

      $condition = @buildCondition(conditionData, nextIndex)

      @_addCondition($condition)
      @_toggleNewConditionMessage()
      @_updateConditionHints()

  _bindRemoveCondition: ->
    ruleModal = this

    @$modal.on 'click', '.condition-remove', (event) ->
      event.preventDefault()

      $condition = $(this).parents('.condition-block:first')
      ruleModal._removeCondition($condition)
      ruleModal._toggleNewConditionMessage()
      ruleModal._updateConditionHints()

  _bindSelectionChanges: ->
    @$modal.on 'change', 'select', (event) =>
      @_updateConditionHints()

  _updateConditionHints: ->
    setTimeout(->
      $mobileDeviceConditions = $('.conditions-wrapper .condition-block:visible').filter(->
        $this = $(this)
        return $this.find('.condition-segment').val() == 'DeviceCondition' and
            $this.find('.condition-operand').val() == 'is' and
            $this.find('.rule_conditions_choices select').val() == 'mobile'
      )
      $('.conditions-wrapper .condition-hint').remove()
      $mobileDeviceConditions.each(->
        $(this).prepend('<div class="condition-hint">Only topbar style Hello Bars can be shown on mobile devices.</div>')
      )
    , 1)

  #-----------  Render a Condition to the Page  -----------#

  _addCondition: ($condition) ->
    @$modal.find('.conditions-wrapper').append($condition.prop('outerHTML'))
    @_removeUrlCondition()

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

  _bindMultipleChoiceActions: ->
    @$modal.on 'click', '.choice-add', (event) ->
      event.preventDefault()

      $inputWrapper = $(this).closest('.multiple-choice')
      $inputBlock   = $(this).closest('.multiple-input-wrapper')

      $inputBlock.clone()
                 .css({opacity: 0, maxHeight: 0})
                 .appendTo($inputWrapper)
                 .animate({opacity: 1, maxHeight: '3em'}, 200)
                 .find('input').val(null)

    @$modal.on 'click', '.choice-remove', (event) ->
      event.preventDefault()

      $(this).closest('.multiple-input-wrapper')
             .animate({opacity: 0, maxHeight: 0}, 200, -> $(@).remove())
