class @RuleModal
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

  _renderValue: ($condition) ->
      $condition.find('.value').hide() # hide the values by default
      $value = $condition.find('.rule_conditions_value')
      segmentValue = $condition.find('.rule_conditions_segment .select').val()
      valueId = $value.find('input').attr('id')
      valueName = $value.find('input').attr('name')

      if $.inArray(segmentValue, ['CountryCondition', 'DeviceSegment']) == 1
        $value.replaceWith('<span>We dont support this yet</span>')
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

  _renderContent: ->
    @$modal.find('.condition').each (index, condition) =>
      $condition = $(condition)
      @_renderValue($condition)

      $condition.on 'change', '.form-control', =>
        @_renderValue($condition)

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

  _addCondition: ->
    nextIndex = @$modal.find('.conditions').length
    templateHTML = $('script#new-condition').html()
    $template = $(templateHTML)
    # update the names on the elements to be submitted properly
    $template.find('[name="segment"]')
             .attr('name', "rule[conditions_attributes][#{nextIndex}][segment]")
    $template.find('[name="operand"]')
             .attr('name', "rule[conditions_attributes][#{nextIndex}][operand]")
    $template.find('[name="value"]')
             .attr('name', "rule[conditions_attributes][#{nextIndex}][value]")
    @$modal.find('.conditions').append($template.html())

  _bindAddCondition: ->
    @$modal.on 'click', '.add', (event) =>
      @_addCondition()

  _bindRemoveCondition: ->
    @$modal.on 'click', '.remove', (event) ->
      $condition = $(this).parents('.condition:first')
      $condition.find('.rule_conditions__destroy input').val(true)
      $condition.hide()

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
