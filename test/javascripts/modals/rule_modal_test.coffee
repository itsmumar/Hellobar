#= require modal
#= require modals/rule_modal

module 'RuleModal.open'

test 'rendering the correct operand for DeviceCondition', ->
  expect(1)

  options =
    ruleData:
      name: 'Rule name'
      conditions: [
        segment: 'DeviceCondition'
      ]

  modal = new RuleModal(options)
  $modal = modal.open()

  $modal.find('select.condition-segment').val('DeviceCondition')
  operands = $modal.find('select.condition-operand option').map ->
    @value

  deepEqual $.makeArray(operands), ['is', 'is_not'], 'filters the correct operands for DeviceCondition'

test 'rendering the correct operand for DateCondition', ->
  expect(1)

  options =
    ruleData:
      name: 'Rule name'
      conditions: [
        segment: 'DateCondition'
      ]

  modal = new RuleModal(options)
  $modal = modal.open()

  $modal.find('select.condition-segment').val('DateCondition')
  operands = $modal.find('select.condition-operand option').map ->
    @value

  deepEqual $.makeArray(operands).sort(), ['is_before', 'is_after', 'is_between'].sort(), 'filteres the correct operands for DateCondition'

test 'rendering the correct operand for UrlCondition', ->
  expect(1)

  options =
    ruleData:
      name: 'Rule name'
      conditions: [
        segment: 'UrlCondition'
      ]

  modal = new RuleModal(options)
  $modal = modal.open()

  $modal.find('select.condition-segment').val('UrlCondition')
  operands = $modal.find('select.condition-operand option').map ->
    @value

  deepEqual $.makeArray(operands), ['includes', 'excludes'], 'filteres the correct operands for UrlCondition'

test 'RuleModal._dateClasses(operand)', ->
  expect(3)

  modal = new RuleModal({})

  equal modal._dateClasses('is_before'), '.end_date.value'
  equal modal._dateClasses('is_after'), '.start_date.value'
  equal modal._dateClasses('is_between'), '.start_date.value, .end_date.value'

test 'RuleModal._renderValue($condition)', (assert) ->
  options =
    ruleData:
      name: 'Rule name'
      conditions: [
        segment: 'DeviceCondition'
      ]

  modal = new RuleModal(options)
  $modal = modal.open()
  $condition = $modal.find('.condition-block:not(".no-condition-message"):first')

  $condition.find('select.condition-segment').val('DeviceCondition').trigger('change')
  modal._renderValue($condition)
  equal $condition.find('.device').prop('disabled'), false, 'it enables the device value when the segment is DeviceCondition'
  equal $condition.find('.url').prop('disabled'), true, 'it disables the url value when the segment is DeviceCondition'
  equal $condition.find('.start_date').prop('disabled'), true, 'it disables the start_date value when the segment is DeviceCondition'
  equal $condition.find('.end_date').prop('disabled'), true, 'it disables the end_date value when the segment is DeviceCondition'

  $condition.find('select.condition-segment').val('UrlCondition').trigger('change')
  modal._renderValue($condition)
  equal $condition.find('.device').prop('disabled'), true, 'it disables the device value when the segment is UrlCondition'
  equal $condition.find('.url').prop('disabled'), false, 'it enables the url value when the segment is UrlCondition'
  equal $condition.find('.start_date').prop('disabled'), true, 'it disables the start_date value when the segment is UrlCondition'
  equal $condition.find('.end_date').prop('disabled'), true, 'it disables the end_date value when the segment is UrlCondition'

  $condition.find('select.condition-segment').val('DateCondition').trigger('change')
  $condition.find('select.condition-operand').val('is_before').trigger('change')
  modal._renderValue($condition)
  equal $condition.find('.device').prop('disabled'), true, 'it disables the device value when the segment is DateCondition'
  equal $condition.find('.url').prop('disabled'), true, 'it disables the url value when the segment is DateCondition'

  $condition.find('select.condition-operand').val('is_before').trigger('change')
  modal._renderValue($condition)
  equal $condition.find('.start_date').prop('disabled'), true, 'it disables the start_date value when the segment is DateCondition and the operand is is_before'
  equal $condition.find('.end_date').prop('disabled'), false, 'it enables the end_date value when the segment is DateCondition and the operand is is_before'

  $condition.find('select.condition-operand').val('is_after').trigger('change')
  modal._renderValue($condition)
  equal $condition.find('.start_date').prop('disabled'), false, 'it enables the start_date value when the segment is DateCondition and the operand is is_after'
  equal $condition.find('.end_date').prop('disabled'), true, 'it disables the end_date value when the segment is DateCondition and the operand is is_after'

  $condition.find('select.condition-operand').val('is_between').trigger('change')
  modal._renderValue($condition)
  equal $condition.find('.start_date').prop('disabled'), false, 'it enables the start_date value when the segment is DateCondition and the operand is is_between'
  equal $condition.find('.end_date').prop('disabled'), false, 'it enables the end_date value when the segment is DateCondition and the operand is is_between'

module 'RuleModal interactions',
  setup: ->
    @modal = new RuleModal(
      ruleData:
        siteId: 1
    )

    $(document).ajaxComplete =>
      @modal.$modal.trigger('ajax-complete')

  teardown: ->
    @modal.$modal.unbind('ajax-complete')
    @modal.close()

asyncTest 'RuleModal closes the modal on a successful form submission event', (assert) ->
  expect(1)
  $('.rules-modal').remove()

  options =
    ruleData:
      siteId: 1
  modal = new RuleModal(options)
  $modal = modal.open()

  $modal.find('form').submit()

  @modal.$modal.on "ajax-complete", =>
    equal $('.rules-modal .show-modal').length, 0, 'removes the modal from the DOM after form submission'
    start()

module 'RuleModal filtering out operands'

test '_validOperands()', ->
  options =
    ruleData:
      name: 'Rule name'
      conditions: [{}]
  modal = new RuleModal(options)

  deepEqual modal._validOperands('DeviceCondition'), ['is', 'is_not'], 'has a valid value for device'
  deepEqual modal._validOperands('DateCondition'), ['is_before', 'is_after', 'is_between'], 'has a valid value for date'
  deepEqual modal._validOperands('UrlCondition'), ['includes', 'excludes'], 'has a valid value for url'

test '_filteredOperands(segment)', ->
  modal = new RuleModal({})
  isOption = '<option value="is"></option>'
  isNotOption = '<option value="is_not"></option>'

  modal.newConditionTemplate = ->
    template =  "<div>"
    template +=   "<select class='condition-operand'>#{isOption}</select>"
    template += "</div>"

  equal modal.filteredOperands('DeviceCondition').val(), $(isOption).val()

  modal.newConditionTemplate = ->
    template =  "<div>"
    template +=   "<select class='condition-operand'>#{isOption}#{isNotOption}</select>"
    template += "</div>"

  expectedValue = modal.filteredOperands("DeviceCondition").map -> @value

  deepEqual $.makeArray(expectedValue), ["is", "is_not"], 'it pulls all option elements that match'
